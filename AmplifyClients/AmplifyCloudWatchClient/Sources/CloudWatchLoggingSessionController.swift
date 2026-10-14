//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import AmplifyFoundationBridge
import AWSCloudWatchLogs
import Combine
import Foundation
import InternalCloudWatchLogging
import Network
import SmithyIdentity

/// Responsible for setting up and tearing-down log sessions for a given namespace
/// according to changes in user authentication sessions.
///
/// - Note: `@unchecked Sendable`: log calls read the session from arbitrary threads while user changes
///   replace it, so every access to the mutable state goes through `lock`.
final class CloudWatchLoggingSessionController: @unchecked Sendable {

    let client: CloudWatchLogsClientProtocol
    let namespace: String
    private let logGroupName: String
    private let region: String
    private let localStoreMaxSizeInMB: Int
    /// Taken while `AmplifyCloudWatchClient` holds its own lock, so never log under it.
    private let lock = NSLock()
    private var session: CloudWatchLoggingSession?
    private var consumer: CloudWatchLoggingConsumer?
    private let logFilter: CloudWatchLoggingFilterBehavior
    private let networkMonitor: LoggingNetworkMonitor
    private let eventSubject: PassthroughSubject<LoggingEvent, Never>
    private let internalLogger = AmplifyFoundation.AmplifyLogging.logger(for: CloudWatchLoggingSessionController.self)

    private var batchSubscription: AnyCancellable? {
        willSet { batchSubscription?.cancel() }
    }

    private var userIdentifier: String?
    private var isEnabled = false

    init(
        client: CloudWatchLogsClientProtocol,
        logFilter: CloudWatchLoggingFilterBehavior,
        namespace: String,
        logGroupName: String,
        region: String,
        localStoreMaxSizeInMB: Int,
        userIdentifier: String?,
        networkMonitor: LoggingNetworkMonitor,
        eventSubject: PassthroughSubject<LoggingEvent, Never>
    ) {
        self.client = client
        self.logFilter = logFilter
        self.namespace = namespace
        self.logGroupName = logGroupName
        self.region = region
        self.localStoreMaxSizeInMB = localStoreMaxSizeInMB
        self.userIdentifier = userIdentifier
        self.networkMonitor = networkMonitor
        self.eventSubject = eventSubject
    }

    func enable() {
        lock.execute {
            // A second session would write the same directory as the first.
            guard !isEnabled else { return }
            isEnabled = true
            updateSession()
            updateConsumer()
            connectProducerAndConsumer()
        }
    }

    func disable() {
        lock.execute {
            isEnabled = false
            // Drop records still queued, so they can't land beside the session `enable()` builds next.
            session?.logger.close()
            batchSubscription = nil
            session = nil
            consumer = nil
        }
    }

    private func updateConsumer() {
        consumer = createConsumer()
    }

    private func connectProducerAndConsumer() {
        guard let consumer else {
            batchSubscription = nil
            return
        }
        guard let producer = session else {
            batchSubscription = nil
            return
        }
        batchSubscription = producer.logBatchPublisher.sink { [weak self] batch in
            guard self?.networkMonitor.isOnline == true else { return }
            Task { [weak self] in
                do {
                    try await consumer.consume(batch: batch)
                } catch {
                    // Keep the batch on failure so it can be retried on the next flush; rotation bounds
                    // disk usage. Deleting here would permanently discard logs on any transient error.
                    self?.internalLogger.error("Error flushing logs: \(error.localizedDescription)")
                    self?.eventSubject.send(.flushLogFailure(context: error.localizedDescription, error: error))
                }
            }
        }
    }

    private func createConsumer() -> CloudWatchLoggingConsumer {
        return CloudWatchLoggingConsumer(
            client: client,
            logGroupName: logGroupName,
            userIdentifier: userIdentifier,
            eventSubject: eventSubject
        )
    }

    private func userIdentifierDidChange() {
        // Discard the OUTGOING user's logs before replacing the session, so we neither delete the new
        // user's logs nor leave the previous user's logs to ship under the new identity.
        discardLogs(of: session)
        updateSession()
        updateConsumer()
        connectProducerAndConsumer()
    }

    private func updateSession() {
        do {
            session = try CloudWatchLoggingSession(
                namespace: namespace,
                userIdentifier: userIdentifier,
                localStoreMaxSizeInMB: localStoreMaxSizeInMB,
                eventSubject: eventSubject
            )
        } catch {
            session = nil
            // Logged from a task: logging here would re-enter `AmplifyCloudWatchClient`'s lock through its sink.
            let description = "\(error)"
            Task { [internalLogger] in
                internalLogger.error("Error creating logging session: \(description)")
            }
        }
    }

    func setCurrentUser(identifier: String?) {
        lock.execute {
            guard userIdentifier != identifier else { return }
            userIdentifier = identifier
            // A disabled controller only records the user; `enable()` builds its session.
            guard isEnabled else { return }
            userIdentifierDidChange()
        }
    }

    func flushLogs() async throws {
        // Skip flushing while offline — every PutLogEvents would fail and (until the batch is retained)
        // waste retries. Matches the connectivity guard on the rotation subscription above.
        guard networkMonitor.isOnline else { return }
        let (logger, consumer) = lock.execute { (session?.logger, self.consumer) }
        guard let logBatches = try await logger?.getFlushableLogBatches() else { return }

        for batch in logBatches {
            // Stop once the session is disabled, leaving its logs for a later flush, or replaced, which discards them.
            guard lock.execute({ session?.logger === logger }) else { return }
            try await consumeLogBatch(batch, with: consumer)
        }
    }

    private func consumeLogBatch(_ batch: LogBatch, with consumer: CloudWatchLoggingConsumer?) async throws {
        guard let consumer else {
            try batch.complete()
            return
        }

        do {
            try await consumer.consume(batch: batch)
        } catch {
            // Keep the batch on failure so it can be retried on the next flush; rotation bounds disk
            // usage. Deleting here would permanently discard logs on any transient error.
            internalLogger.error("Error flushing logs: \(error.localizedDescription)")
            eventSubject.send(.flushLogFailure(context: error.localizedDescription, error: error))
        }
    }

    /// Discards the outgoing session's logs before a later session can start in its directory.
    private func discardLogs(of session: CloudWatchLoggingSession?) {
        do {
            try session?.logger.discardLogs()
        } catch {
            // Logged from a task: logging here would re-enter `AmplifyCloudWatchClient`'s lock through its sink.
            let description = "\(error)"
            Task { [internalLogger] in
                internalLogger.error("Error resetting previous user's logs: \(description)")
            }
        }
    }
}

// MARK: - AmplifyFoundation.Logger conformance

extension CloudWatchLoggingSessionController: AmplifyFoundation.Logger {
    func error(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        guard let logger = sessionLogger(for: .error) else { return }
        if let err = error() {
            logger.error(error: err)
        } else {
            logger.error(message())
        }
    }

    func warn(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        sessionLogger(for: .warn)?.warn(message())
    }

    func info(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        sessionLogger(for: .info)?.info(message())
    }

    func debug(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        sessionLogger(for: .debug)?.debug(message())
    }

    func verbose(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        sessionLogger(for: .verbose)?.verbose(message())
    }

    func log(_ logLevel: LogLevel, _ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        sessionLogger(for: logLevel)?._record(level: logLevel, message: message())
    }

    /// The current session's logger, or `nil` when `logFilter` rejects `level` for the current user.
    private func sessionLogger(for level: LogLevel) -> RotatingLogger? {
        let (logger, userIdentifier) = lock.execute { (session?.logger, self.userIdentifier) }
        guard logFilter.canLog(withNamespace: namespace, logLevel: level, userIdentifier: userIdentifier) else { return nil }
        return logger
    }
}
