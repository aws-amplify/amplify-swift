//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation

/// A client for recording enriched analytics events.
///
/// Collects device, app, session, and SDK metadata and produces
/// ``EnrichedEvent`` instances with Pinpoint-compatible JSON output.
/// Session boundaries are sent to the sink as `_session.start` and
/// `_session.stop` events, in order with recorded events.
///
/// A session pauses when the app goes to the background. A paused session
/// ends when its timeout fires, or at the next foreground or ``record(_:attributes:metrics:)``
/// if the timeout has passed by then. On iOS the app is usually suspended
/// before a short timeout fires, so the stop often goes out at the next
/// foreground. If the app is terminated while suspended, the stop is not
/// sent. Call ``close()`` to send the final stop.
///
/// ## Usage
///
/// ```swift
/// let client = AmplifyEventEnrichmentClient(
///     appId: "my-app",
///     sdkMetadata: SDKMetadata(name: "amplify-swift", version: "2.58.0")
/// )
///
/// let event = try await client.record("button_clicked")
/// print(try event.toJson())
///
/// await client.close()
/// ```
@available(iOS 13.0, macOS 12.0, tvOS 13.0, watchOS 9.0, *)
public actor AmplifyEventEnrichmentClient {
    private let logger: Logger
    private let globalFields: GlobalFieldsManager
    private let makeEvent: EventFactory
    private let sessionManager: SessionManager
    private var activityTracker: ActivityTracker?
    private var closed = false
    private var closing: Task<Void, Never>?

    // Every send goes through this one queue and its one consumer, so the sink
    // sees events in the order they were queued, one at a time.
    private let deliveries: AsyncStream<Delivery>.Continuation
    private let consumer: Task<Void, Never>

    // Lifecycle changes go through one queue and one consumer too, so the
    // session manager handles them in the order they were posted.
    private let lifecycleChanges: AsyncStream<LifecycleChange>.Continuation?

    /// Initializes a new event enrichment client.
    ///
    /// The `clientId` is resolved automatically from `UserDefaults` using a
    /// read-or-create pattern with the key `com.amplifyframework.device_id`,
    /// which is shared with `AmplifyConnectClient`'s `DeviceIdProvider` so both
    /// clients report the same identifier for a device.
    ///
    /// When `deviceMetadata` is nil, the client resolves platform, OS version,
    /// manufacturer, model, and locale via ``PlatformDeviceMetadataProvider``.
    ///
    /// - Parameters:
    ///   - appId: Application identifier used in the event envelope and session ID.
    ///   - sdkMetadata: SDK-level metadata for events.
    ///   - appMetadata: Application-level metadata. If nil, created from `appId`.
    ///   - deviceMetadata: Device-level metadata. If nil, resolved via platform APIs.
    ///   - initialUserId: User identifier stamped on events from the start, including
    ///     the launch `_session.start`.
    ///   - initialGlobalAttributes: Global attributes applied before the launch session starts.
    ///   - initialGlobalMetrics: Global metrics applied before the launch session starts.
    ///   - options: Configuration options. With `autoSessionTracking`, a session
    ///     starts here and its `_session.start` event is queued for the sink.
    ///   - sink: Optional transport sink for enriched events.
    @MainActor
    public init(
        appId: String,
        sdkMetadata: SDKMetadata,
        appMetadata: AppMetadata? = nil,
        deviceMetadata: DeviceMetadata? = nil,
        initialUserId: String? = nil,
        initialGlobalAttributes: [String: String] = [:],
        initialGlobalMetrics: [String: Double] = [:],
        options: EventEnrichmentClientOptions = EventEnrichmentClientOptions(),
        sink: (any EventSink)? = nil
    ) {
        let resolvedAppMetadata = appMetadata ?? AppMetadata(appId: appId)
        let resolvedDeviceMetadata = deviceMetadata ?? PlatformDeviceMetadataProvider().getDeviceMetadata()
        let resolvedClientId = ClientIDProvider.resolve()

        let logger = AmplifyLogging.logger(for: AmplifyEventEnrichmentClient.self)
        let globalFields = GlobalFieldsManager()
        globalFields.userId = initialUserId
        initialGlobalAttributes.forEach { globalFields.addAttribute($0.key, value: $0.value) }
        initialGlobalMetrics.forEach { globalFields.addMetric($0.key, value: $0.value) }
        let makeEvent: EventFactory = { eventType, session, attributes, metrics in
            let fields = globalFields.snapshot()
            return EnrichedEvent(
                eventId: UUID().uuidString,
                eventType: eventType,
                eventTimestamp: Int64(Date().timeIntervalSince1970 * 1_000),
                session: session,
                attributes: fields.attributes.merging(attributes) { _, event in event },
                metrics: fields.metrics.merging(metrics) { _, event in event },
                device: resolvedDeviceMetadata,
                app: resolvedAppMetadata,
                sdk: sdkMetadata,
                clientId: resolvedClientId,
                userId: fields.userId
            )
        }

        let (stream, deliveries) = AsyncStream.makeStream(of: Delivery.self)

        self.logger = logger
        self.globalFields = globalFields
        self.makeEvent = makeEvent
        self.deliveries = deliveries
        // Started here so it exists before anything can be queued. Detached, and
        // capturing no `self`, so it neither runs on the main actor nor needs a
        // fully initialized actor. The stream buffers what is queued before it runs.
        self.consumer = Task.detached {
            for await delivery in stream {
                if let event = delivery.event {
                    await sink?.send(event)
                    logger.verbose("Recorded event: \(event.eventType)")
                }
                delivery.sent?.signal()
            }
        }
        let emitSessionEvents = options.emitSessionEvents
        let sessionManager = SessionManager(
            appId: resolvedAppMetadata.appId,
            sessionTimeout: options.sessionTimeout,
            generateId: { UUID().uuidString },
            startingSession: options.autoSessionTracking,
            onBoundary: { boundary, session in
                guard emitSessionEvents else { return }
                // Built and queued inside the transition, so boundaries are
                // queued in transition order with the fields of that moment.
                deliveries.yield(Delivery(event: makeEvent(boundary.eventType, session, [:], [:]), sent: nil))
            }
        )
        self.sessionManager = sessionManager
        if options.autoSessionTracking {
            let (changes, lifecycleChanges) = AsyncStream.makeStream(of: LifecycleChange.self)
            Task.detached {
                for await change in changes {
                    switch change {
                    case .paused: await sessionManager.handleAppPaused()
                    case .resumed: await sessionManager.handleAppResumed()
                    }
                }
            }
            self.lifecycleChanges = lifecycleChanges
            self.activityTracker = ActivityTracker(
                onPause: { lifecycleChanges.yield(.paused) },
                onResume: { lifecycleChanges.yield(.resumed) }
            )
            // A client created in the background sees no didEnterBackground, so
            // the launch session is paused here, ahead of any later notification.
            if ActivityTracker.isAppInBackground() {
                lifecycleChanges.yield(.paused)
            }
        } else {
            self.lifecycleChanges = nil
            self.activityTracker = nil
        }
    }

    /// Records an event and returns the enriched result once the sink has
    /// received it.
    ///
    /// Starts a session first if none is running, queueing its `_session.start`
    /// ahead of the event.
    ///
    /// Events are sent one at a time, in the order they were queued, so this
    /// also waits for every event queued ahead of it. Cancelling the caller does
    /// not cancel the send.
    ///
    /// - Parameters:
    ///   - eventType: The type/name of the event.
    ///   - attributes: Per-event string attributes (merged with globals).
    ///   - metrics: Per-event numeric metrics (merged with globals).
    /// - Returns: The enriched event.
    /// - Throws: ``EventEnrichmentError/clientClosed(_:_:_:)`` if the client has been closed.
    @discardableResult
    public func record(
        _ eventType: String,
        attributes: [String: String] = [:],
        metrics: [String: Double] = [:]
    ) async throws -> EnrichedEvent {
        guard !closed else {
            throw EventEnrichmentError.clientClosed(
                "Client has been closed",
                "Create a new AmplifyEventEnrichmentClient instance."
            )
        }

        let makeEvent = makeEvent
        let deliveries = deliveries
        let sent = DeliverySignal()
        let event = await sessionManager.withRecordingSession { session in
            let event = makeEvent(eventType, session, attributes, metrics)
            if case .terminated = deliveries.yield(Delivery(event: event, sent: sent)) {
                sent.signal()
            }
            return event
        }
        // Only a disposed session manager returns nil.
        guard let event else {
            throw EventEnrichmentError.clientClosed(
                "Client has been closed",
                "Create a new AmplifyEventEnrichmentClient instance."
            )
        }

        await sent.wait()
        return event
    }

    /// Starts a new session manually, ending the current one first.
    /// Returns once the sink has received the new session's start.
    /// No-op once the client is closed.
    public func startSession() async {
        guard !closed else { return }
        await sessionManager.startSession()
        await waitForQueuedDeliveries()
    }

    /// Stops the current session and returns once the sink has received its stop.
    /// No-op if no session is running or once the client is closed.
    ///
    /// Returning to the foreground does not start a new session afterwards;
    /// recording an event or calling ``startSession()`` does.
    public func stopSession() async {
        guard !closed else { return }
        guard await sessionManager.stopSession() else { return }
        await waitForQueuedDeliveries()
    }

    /// Returns once everything queued so far, boundaries included, has been sent.
    private func waitForQueuedDeliveries() async {
        let sent = DeliverySignal()
        if case .terminated = deliveries.yield(Delivery(event: nil, sent: sent)) {
            sent.signal()
        }
        await sent.wait()
    }

    /// Sets the user identifier stamped on subsequent events.
    public func setUserId(_ userId: String?) {
        globalFields.userId = userId
    }

    /// Adds a global attribute stamped on every subsequent event.
    public func addGlobalAttribute(_ key: String, value: String) async {
        globalFields.addAttribute(key, value: value)
    }

    /// Removes a global attribute.
    public func removeGlobalAttribute(_ key: String) async {
        globalFields.removeAttribute(key)
    }

    /// Adds a global metric stamped on every subsequent event.
    public func addGlobalMetric(_ key: String, value: Double) async {
        globalFields.addMetric(key, value: value)
    }

    /// Removes a global metric.
    public func removeGlobalMetric(_ key: String) async {
        globalFields.removeMetric(key)
    }

    /// The current session state. Internal, for tests to observe lifecycle handling.
    var sessionState: SessionState {
        get async { await sessionManager.state }
    }

    /// Whether lifecycle notifications are still being observed. Internal, for tests.
    var isTrackingLifecycle: Bool {
        activityTracker != nil
    }

    /// Releases resources and stops session tracking.
    ///
    /// Queues the final `_session.stop` and returns once the sink has received
    /// it and everything queued before it. Nothing reaches the sink afterwards.
    /// The client cannot be reused after closing. Concurrent calls share one
    /// teardown and all return once it finishes.
    public func close() async {
        closed = true
        let teardown = closing ?? Task { await tearDown() }
        closing = teardown
        await teardown.value
    }

    private func tearDown() async {
        // Dispose first: the session manager then ignores lifecycle callbacks
        // still in flight, so none can start a session on a closed client.
        await sessionManager.dispose()
        await activityTracker?.stopTracking()
        activityTracker = nil
        lifecycleChanges?.finish()
        // Nothing can queue after dispose(), so the final stop is the last delivery.
        deliveries.finish()
        await consumer.value
        logger.info("Client closed")
    }

    deinit {
        // Queues the session's stop before the streams finish. dispose() is a
        // no-op if close() already ran, so the stop is never sent twice.
        Task { [sessionManager, lifecycleChanges, deliveries] in
            await sessionManager.dispose()
            lifecycleChanges?.finish()
            deliveries.finish()
        }
    }
}

/// A lifecycle change queued for the session manager.
private enum LifecycleChange: Sendable {
    case paused
    case resumed
}
