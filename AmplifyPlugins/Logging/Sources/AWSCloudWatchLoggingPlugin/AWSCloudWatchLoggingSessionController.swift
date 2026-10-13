//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSClientRuntime
import AWSCloudWatchLogs
import AWSPluginsCore
import Combine
import Foundation
import InternalCloudWatchLogging
@_spi(PluginHTTPClientEngine) import InternalAmplifyCredentials
import Network
import SmithyIdentity

/// Responsible for setting up and tearing-down log sessions for a given category/tag according to changes in
/// user authentication sessions.
///
/// - Tag: CloudWatchLogSessionController
/// - Note: `@unchecked Sendable`: log calls read the session from arbitrary threads while user changes
///   replace it, so every access to the mutable state goes through `lock`. Members that already hold the
///   lock read the underscored storage directly, because `NSLock` is not recursive.
final class AWSCloudWatchLoggingSessionController: @unchecked Sendable {

    var client: CloudWatchLogsClientProtocol? {
        get { lock.execute { _client } }
        set { lock.execute { _client = newValue } }
    }
    let namespace: String?
    private let logGroupName: String
    private let region: String
    private let localStoreMaxSizeInMB: Int
    private let credentialIdentityResolver: any AWSCredentialIdentityResolver
    private let authentication: AuthCategoryUserBehavior
    private let category: String
    /// Taken while the category client holds its own lock, so never call `Amplify.Logging` under it.
    private let lock = NSLock()
    /// Guarded by `lock`. Read through `client` from unlocked contexts.
    private var _client: CloudWatchLogsClientProtocol?
    private var session: AWSCloudWatchLoggingSession?
    private var consumer: LogBatchConsumer?
    private let logFilter: AWSCloudWatchLoggingFilterBehavior
    private let networkMonitor: LoggingNetworkMonitor

    private var batchSubscription: AnyCancellable? {
        willSet {
            batchSubscription?.cancel()
        }
    }

    private var authSubscription: AnyCancellable? {
        willSet {
            authSubscription?.cancel()
        }
    }
    private var userIdentifier: String?
    private var isEnabled = false

    /// Guarded by `lock`. Read through `logLevel` from unlocked contexts.
    private var _logLevel: LogLevel

    var logLevel: LogLevel {
        get { lock.execute { _logLevel } }
        set {
            lock.execute {
                _logLevel = newValue
                session?.logger.logLevel = newValue
            }
        }
    }

    /// - Tag: CloudWatchLogSessionController.init
    init(
        credentialIdentityResolver: some AWSCredentialIdentityResolver,
        authentication: AuthCategoryUserBehavior,
        logFilter: AWSCloudWatchLoggingFilterBehavior,
        category: String,
        namespace: String?,
        logLevel: LogLevel,
        logGroupName: String,
        region: String,
        localStoreMaxSizeInMB: Int,
        userIdentifier: String?,
        networkMonitor: LoggingNetworkMonitor
    ) {
        self.credentialIdentityResolver = credentialIdentityResolver
        self.authentication = authentication
        self.logFilter = logFilter
        self.category = category
        self.namespace = namespace
        self._logLevel = logLevel
        self.logGroupName = logGroupName
        self.region = region
        self.localStoreMaxSizeInMB = localStoreMaxSizeInMB
        self.userIdentifier = userIdentifier
        self.networkMonitor = networkMonitor
    }

    func enable() {
        lock.execute {
            isEnabled = true
            updateSession()
            updateConsumer()
            connectProducerAndConsumer()
        }
    }

    func disable() {
        lock.execute {
            isEnabled = false
            batchSubscription = nil
            authSubscription = nil
            session = nil
            consumer = nil
        }
    }

    private func updateConsumer() {
        consumer = try? createConsumer()
    }

    private func createConsumer() throws -> LogBatchConsumer? {
        if _client == nil {
            var configuration = try CloudWatchLogsClient.CloudWatchLogsClientConfig(
                awsCredentialIdentityResolver: credentialIdentityResolver,
                region: region,
                signingRegion: region
            )

            configuration.httpClientEngine = .userAgentEngine(for: configuration)

            _client = CloudWatchLogsClient(config: configuration)
        }

        guard let cloudWatchClient = _client else { return nil }
        return CloudWatchLoggingConsumer(
            client: cloudWatchClient,
            logGroupName: logGroupName,
            userIdentifier: userIdentifier
        )
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

            // Capture strong references to consumer and batch before the async task
            let strongConsumer = consumer
            let strongBatch = batch

            Task {
                do {
                    try await strongConsumer.consume(batch: strongBatch)
                } catch {
                    Amplify.Logging.default.error("Error flushing logs with error \(error.localizedDescription)")
                    let payload = HubPayload(eventName: HubPayload.EventName.Logging.flushLogFailure, context: error.localizedDescription)
                    Amplify.Hub.dispatch(to: HubChannel.logging, payload: payload)
                    try strongBatch.complete()
                }
            }
        }
    }

    private func userIdentifierDidChange() {
        resetLogs(for: session)
        updateSession()
        updateConsumer()
        connectProducerAndConsumer()
    }

    private func updateSession() {
        do {
            session = try AWSCloudWatchLoggingSession(
                category: category,
                namespace: namespace,
                logLevel: _logLevel,
                userIdentifier: userIdentifier,
                localStoreMaxSizeInMB: localStoreMaxSizeInMB
            )
        } catch {
            session = nil
            print(error)
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
        let (logger, consumer) = lock.execute { (session?.logger, self.consumer) }
        guard let logBatches = try await logger?.getLogBatches() else { return }

        for batch in logBatches {
            // Stop if disabled mid-flush; the remaining logs stay on disk for a later flush.
            guard lock.execute({ isEnabled }) else { return }
            try await consumeLogBatch(batch, with: consumer)
        }
    }

    private func consumeLogBatch(_ batch: LogBatch, with consumer: LogBatchConsumer?) async throws {
        // Check if consumer exists before trying to use it
        guard let consumer else {
            // If consumer is nil, still mark the batch as completed to prevent memory leaks
            try batch.complete()
            return
        }

        do {
            try await consumer.consume(batch: batch)
        } catch {
            Amplify.Logging.default.error("Error flushing logs with error \(error.localizedDescription)")
            let payload = HubPayload(eventName: HubPayload.EventName.Logging.flushLogFailure, context: error.localizedDescription)
            Amplify.Hub.dispatch(to: HubChannel.logging, payload: payload)
            try batch.complete()
        }
    }

    /// Captures the outgoing session's logger now, so the reset can't hit the session that replaces it.
    private func resetLogs(for session: AWSCloudWatchLoggingSession?) {
        guard let logger = session?.logger else { return }
        Task {
            do {
                try await logger.resetLogs()
            } catch {
                Amplify.Logging.error("Error resetting logs with \(error)")
            }
        }
    }
}

extension AWSCloudWatchLoggingSessionController: Logger {
    func error(_ message: @autoclosure () -> String) {
        sessionLogger(for: .error)?.error(message())
    }

    func error(error: Error) {
        sessionLogger(for: .error)?.error(error: error)
    }

    func warn(_ message: @autoclosure () -> String) {
        sessionLogger(for: .warn)?.warn(message())
    }

    func info(_ message: @autoclosure () -> String) {
        sessionLogger(for: .info)?.info(message())
    }

    func debug(_ message: @autoclosure () -> String) {
        sessionLogger(for: .debug)?.debug(message())
    }

    func verbose(_ message: @autoclosure () -> String) {
        sessionLogger(for: .verbose)?.verbose(message())
    }

    /// The current session's logger, or `nil` when `logFilter` rejects `level` for the current user.
    private func sessionLogger(for level: LogLevel) -> RotatingLogger? {
        let (logger, userIdentifier) = lock.execute { (session?.logger, self.userIdentifier) }
        guard logFilter.canLog(withCategory: category, logLevel: level, userIdentifier: userIdentifier) else { return nil }
        return logger
    }
}
