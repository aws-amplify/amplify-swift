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
/// print(event.toJson())
///
/// await client.close()
/// ```
@available(iOS 13.0, macOS 12.0, tvOS 13.0, watchOS 9.0, *)
public actor AmplifyEventEnrichmentClient {
    private let appMetadata: AppMetadata
    private let deviceMetadata: DeviceMetadata
    private let sdkMetadata: SDKMetadata
    private let clientId: String
    private let sink: (any EventSink)?
    private let logger: Logger
    private let globalFields: GlobalFieldsManager
    private let sessionManager: SessionManager
    private let activityTracker: ActivityTracker?
    private var userId: String?
    private var closed = false

    /// Initializes a new event enrichment client.
    ///
    /// The `clientId` is resolved automatically from `UserDefaults` using a
    /// read-or-create pattern with the key
    /// `com.amazonaws.amplify.event_enrichment.client_id`.
    ///
    /// - Parameters:
    ///   - appId: Application identifier used in the event envelope and session ID.
    ///   - sdkMetadata: SDK-level metadata for events.
    ///   - appMetadata: Application-level metadata. If nil, created from `appId`.
    ///   - deviceMetadata: Device-level metadata. If nil, uses platform defaults.
    ///   - options: Configuration options.
    ///   - sink: Optional transport sink for enriched events.
    public init(
        appId: String,
        sdkMetadata: SDKMetadata,
        appMetadata: AppMetadata? = nil,
        deviceMetadata: DeviceMetadata? = nil,
        options: EventEnrichmentClientOptions = EventEnrichmentClientOptions(),
        sink: (any EventSink)? = nil
    ) {
        let resolvedAppMetadata = appMetadata ?? AppMetadata(appId: appId)
        let resolvedDeviceMetadata = deviceMetadata ?? DeviceMetadata()
        let resolvedClientId = ClientIDProvider.resolve()

        self.appMetadata = resolvedAppMetadata
        self.deviceMetadata = resolvedDeviceMetadata
        self.sdkMetadata = sdkMetadata
        self.clientId = resolvedClientId
        self.sink = sink
        self.logger = AmplifyLogging.logger(for: AmplifyEventEnrichmentClient.self)
        self.globalFields = GlobalFieldsManager()
        let sessionManager = SessionManager(
            appId: resolvedAppMetadata.appId,
            sessionTimeout: options.sessionTimeout,
            generateId: { UUID().uuidString }
        )
        self.sessionManager = sessionManager
        if options.autoSessionTracking {
            self.activityTracker = ActivityTracker(
                onPause: { Task { await sessionManager.handleAppPaused() } },
                onResume: { Task { await sessionManager.handleAppResumed() } }
            )
        } else {
            self.activityTracker = nil
        }
    }

    /// Records an event and returns the enriched result.
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

        await sessionManager.startSession()

        let globalAttributes = await globalFields.attributes
        let globalMetrics = await globalFields.metrics

        var mergedAttributes = globalAttributes
        for (key, value) in attributes {
            mergedAttributes[key] = value
        }

        var mergedMetrics = globalMetrics
        for (key, value) in metrics {
            mergedMetrics[key] = value
        }

        guard let session = await sessionManager.session else {
            throw EventEnrichmentError.unknown(
                "No active session",
                "Call startSession() before recording events."
            )
        }

        let event = EnrichedEvent(
            eventId: UUID().uuidString,
            eventType: eventType,
            eventTimestamp: Int64(Date().timeIntervalSince1970 * 1_000),
            session: session,
            attributes: mergedAttributes,
            metrics: mergedMetrics,
            device: deviceMetadata,
            app: appMetadata,
            sdk: sdkMetadata,
            clientId: clientId,
            userId: userId
        )

        await sink?.send(event)
        logger.verbose("Recorded event: \(eventType)")
        return event
    }

    /// Starts a new session manually.
    public func startSession() async {
        await sessionManager.startSession()
    }

    /// Stops the current session.
    public func stopSession() async {
        await sessionManager.stopSession()
    }

    /// Sets the user identifier stamped on subsequent events.
    public func setUserId(_ userId: String?) {
        self.userId = userId
    }

    /// Adds a global attribute stamped on every subsequent event.
    public func addGlobalAttribute(_ key: String, value: String) async {
        await globalFields.addAttribute(key, value: value)
    }

    /// Removes a global attribute.
    public func removeGlobalAttribute(_ key: String) async {
        await globalFields.removeAttribute(key)
    }

    /// Adds a global metric stamped on every subsequent event.
    public func addGlobalMetric(_ key: String, value: Double) async {
        await globalFields.addMetric(key, value: value)
    }

    /// Removes a global metric.
    public func removeGlobalMetric(_ key: String) async {
        await globalFields.removeMetric(key)
    }

    /// Releases resources and stops session tracking.
    ///
    /// The client cannot be reused after closing.
    public func close() async {
        closed = true
        await sessionManager.stopSession()
        logger.info("Client closed")
    }
}
