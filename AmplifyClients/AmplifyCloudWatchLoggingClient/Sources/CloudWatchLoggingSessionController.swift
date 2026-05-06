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
final class CloudWatchLoggingSessionController: @unchecked Sendable {

    let client: CloudWatchLogsClientProtocol
    let namespace: String
    private let logGroupName: String
    private let region: String
    private let localStoreMaxSizeInMB: Int
    private var session: CloudWatchLoggingSession?
    private var consumer: CloudWatchLoggingConsumer?
    private let logFilter: CloudWatchLoggingFilterBehavior
    private let networkMonitor: LoggingNetworkMonitor
    private let eventSubject: PassthroughSubject<LoggingEvent, Never>
    private let internalLogger = AmplifyFoundation.AmplifyLogging.logger(for: CloudWatchLoggingSessionController.self)

    private var batchSubscription: AnyCancellable? {
        willSet { batchSubscription?.cancel() }
    }

    private var userIdentifier: String? {
        didSet {
            if oldValue != userIdentifier {
                userIdentifierDidChange()
            }
        }
    }

    var logLevel: LogLevel {
        didSet {
            session?.logger.logLevel = logLevel
        }
    }

    init(
        client: CloudWatchLogsClientProtocol,
        logFilter: CloudWatchLoggingFilterBehavior,
        namespace: String,
        logLevel: LogLevel,
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
        self.logLevel = logLevel
        self.logGroupName = logGroupName
        self.region = region
        self.localStoreMaxSizeInMB = localStoreMaxSizeInMB
        self.userIdentifier = userIdentifier
        self.networkMonitor = networkMonitor
        self.eventSubject = eventSubject
    }

    func enable() {
        updateSession()
        updateConsumer()
        connectProducerAndConsumer()
    }

    func disable() {
        batchSubscription = nil
        session = nil
        consumer = nil
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
            guard let self, self.networkMonitor.isOnline == true else { return }
            let strongConsumer = consumer
            let strongBatch = batch
            Task { [weak self] in
                do {
                    try await strongConsumer.consume(batch: strongBatch)
                } catch {
                    self?.internalLogger.error("Error flushing logs: \(error.localizedDescription)")
                    self?.eventSubject.send(.flushLogFailure(context: error.localizedDescription, error: error))
                    try strongBatch.complete()
                }
            }
        }
    }

    private func createConsumer() -> CloudWatchLoggingConsumer {
        return CloudWatchLoggingConsumer(
            client: client,
            logGroupName: logGroupName,
            userIdentifier: userIdentifier
        )
    }

    private func userIdentifierDidChange() {
        resetCurrentLogs()
        updateSession()
        updateConsumer()
        connectProducerAndConsumer()
    }

    private func updateSession() {
        do {
            session = try CloudWatchLoggingSession(
                namespace: namespace,
                logLevel: logLevel,
                userIdentifier: userIdentifier,
                localStoreMaxSizeInMB: localStoreMaxSizeInMB,
                eventSubject: eventSubject
            )
        } catch {
            session = nil
            internalLogger.error("Error creating logging session: \(error)")
        }
    }

    func setCurrentUser(identifier: String?) {
        userIdentifier = identifier
    }

    func flushLogs() async throws {
        guard let logBatches = try await session?.logger.getLogBatches() else { return }

        for batch in logBatches {
            try await consumeLogBatch(batch)
        }
    }

    private func consumeLogBatch(_ batch: LogBatch) async throws {
        guard let consumer else {
            try batch.complete()
            return
        }

        do {
            try await consumer.consume(batch: batch)
        } catch {
            internalLogger.error("Error flushing logs: \(error.localizedDescription)")
            eventSubject.send(.flushLogFailure(context: error.localizedDescription, error: error))
            try batch.complete()
        }
    }

    private func resetCurrentLogs() {
        Task { [weak self] in
            do {
                try await self?.session?.logger.resetLogs()
            } catch {
                self?.internalLogger.error("Error resetting logs: \(error)")
            }
        }
    }
}

// MARK: - AmplifyFoundation.Logger conformance

extension CloudWatchLoggingSessionController: AmplifyFoundation.Logger {
    func error(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        guard logFilter.canLog(withNamespace: namespace, logLevel: .error, userIdentifier: userIdentifier) else { return }
        if let err = error() {
            session?.logger.error(error: err)
        } else {
            session?.logger.error(message())
        }
    }

    func warn(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        guard logFilter.canLog(withNamespace: namespace, logLevel: .warn, userIdentifier: userIdentifier) else { return }
        session?.logger.warn(message())
    }

    func info(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        guard logFilter.canLog(withNamespace: namespace, logLevel: .info, userIdentifier: userIdentifier) else { return }
        session?.logger.info(message())
    }

    func debug(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        guard logFilter.canLog(withNamespace: namespace, logLevel: .debug, userIdentifier: userIdentifier) else { return }
        session?.logger.debug(message())
    }

    func verbose(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        guard logFilter.canLog(withNamespace: namespace, logLevel: .verbose, userIdentifier: userIdentifier) else { return }
        session?.logger.verbose(message())
    }

    func log(_ logLevel: LogLevel, _ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        guard logFilter.canLog(withNamespace: namespace, logLevel: logLevel, userIdentifier: userIdentifier) else { return }
        session?.logger._record(level: logLevel, message: message())
    }
}
