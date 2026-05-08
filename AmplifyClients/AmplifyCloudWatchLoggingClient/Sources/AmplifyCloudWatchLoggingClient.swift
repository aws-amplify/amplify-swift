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

/// A closure for customizing the underlying `CloudWatchLogsClient` configuration.
@_spi(AmplifyExperimental)
public typealias AmplifyCloudWatchLoggingClientConfigurationProvider = (
    inout AWSCloudWatchLogs.CloudWatchLogsClient.CloudWatchLogsClientConfig
) -> Void

/// A standalone client for sending log events to Amazon CloudWatch Logs.
///
/// Provides namespace-based logging with automatic batching, local file persistence
/// via log rotation, and configurable flush strategies.
///
/// Conforms to `LogSinkBehavior` so it can be registered with `AmplifyLogging.addSink()`
/// to capture all framework log messages and forward them to CloudWatch.
///
/// Example usage:
/// ```swift
/// let loggingClient = AmplifyCloudWatchLoggingClient(
///     region: "us-east-1",
///     credentialsProvider: credentialsProvider,
///     options: .init(logGroupName: "/app/my-ios-app")
/// )
///
/// // Register as a sink to capture all AmplifyLogging messages
/// AmplifyLogging.addSink(loggingClient)
///
/// let log = AmplifyLogging.logger(for: "Storage")
/// log.info("Upload started")
///
/// try await loggingClient.flushLogs()
/// ```
@available(iOS 13.0, macOS 12.0, tvOS 13.0, watchOS 9.0, *)
@_spi(AmplifyExperimental)
public class AmplifyCloudWatchLoggingClient: AmplifyFoundation.LogSinkBehavior {

    private var enabled: Bool = true

    private let lock = NSLock()
    private let logGroupName: String
    private let region: String
    private let credentialIdentityResolver: any AWSCredentialIdentityResolver
    private var loggersByKey: [LoggerKey: CloudWatchLoggingSessionController] = [:]
    private let localStoreMaxSizeInMB: Int
    private var automaticFlushLogMonitor: CloudWatchLoggingMonitor?
    private let logFilter: CloudWatchLoggingFilter
    private var userIdentifier: String?
    private let networkMonitor: LoggingNetworkMonitor
    private let configureClient: AmplifyCloudWatchLoggingClientConfigurationProvider?
    private let logger = AmplifyFoundation.AmplifyLogging.logger(for: AmplifyCloudWatchLoggingClient.self)
    private let eventSubject = PassthroughSubject<LoggingEvent, Never>()

    private let sinkId = "AmplifyCloudWatchLoggingSink-\(UUID().uuidString)"

    /// A Combine publisher for logging events (flush failures, write failures, etc.).
    /// Subscribe via `events.sink { event in ... }`.
    public var events: AnyPublisher<LoggingEvent, Never> { eventSubject.eraseToAnyPublisher() }

    // MARK: - LogSinkBehavior

    public var id: String { sinkId }

    public func isEnabled(for logLevel: AmplifyFoundation.LogLevel) -> Bool {
        return enabled
    }

    public func emit(message: AmplifyFoundation.LogMessage) {
        guard enabled else { return }
        let controller = getOrCreateController(namespace: message.name, logLevel: message.level)
        controller.log(message.level, message.content, message.error)
    }

    /// Configuration options for AmplifyCloudWatchLoggingClient.
    public struct Options {
        public let logGroupName: String
        public let localStoreMaxSizeInMB: Int
        public let flushStrategy: FlushStrategy
        public let loggingConstraints: LoggingConstraints
        public let configureClient: AmplifyCloudWatchLoggingClientConfigurationProvider?

        public init(
            logGroupName: String,
            localStoreMaxSizeInMB: Int = 5,
            flushStrategy: FlushStrategy = .interval(),
            loggingConstraints: LoggingConstraints = LoggingConstraints(),
            configureClient: AmplifyCloudWatchLoggingClientConfigurationProvider? = nil
        ) {
            self.logGroupName = logGroupName
            self.localStoreMaxSizeInMB = localStoreMaxSizeInMB
            self.flushStrategy = flushStrategy
            self.loggingConstraints = loggingConstraints
            self.configureClient = configureClient
        }
    }

    /// Initializes a new AmplifyCloudWatchLoggingClient instance.
    public init(
        region: String,
        credentialsProvider: any AmplifyFoundation.AWSCredentialsProvider,
        options: Options
    ) {
        self.region = region
        self.logGroupName = options.logGroupName
        self.localStoreMaxSizeInMB = options.localStoreMaxSizeInMB
        self.credentialIdentityResolver = FoundationToSDKCredentialsAdapter(provider: credentialsProvider)
        self.networkMonitor = NWPathMonitor()
        self.networkMonitor.startMonitoring(
            using: DispatchQueue(label: "com.amazonaws.amplify.cloudwatchlogging.networkmonitor")
        )
        self.configureClient = options.configureClient

        self.logFilter = CloudWatchLoggingFilter(loggingConstraints: options.loggingConstraints)

        if case .interval(let interval) = options.flushStrategy {
            self.automaticFlushLogMonitor = CloudWatchLoggingMonitor(
                flushIntervalInSeconds: interval,
                eventDelegate: self
            )
            automaticFlushLogMonitor?.setAutomaticFlushIntervals()
        }
    }

    // MARK: - Lifecycle

    /// Enable logging and automatic flushing.
    public func enable() {
        enabled = true
        lock.execute {
            for controller in loggersByKey.values {
                controller.enable()
            }
        }
    }

    /// Disable logging and automatic flushing.
    public func disable() {
        enabled = false
        lock.execute {
            for controller in loggersByKey.values {
                controller.disable()
            }
        }
    }

    /// Flush all pending log entries to CloudWatch.
    public func flushLogs() async throws {
        guard enabled else { return }
        for logger in loggersByKey.values {
            try await logger.flushLogs()
        }
    }

    /// Returns the underlying AWS CloudWatch Logs SDK client.
    public func getCloudWatchLogsClient() throws -> AWSCloudWatchLogs.CloudWatchLogsClient {
        guard let controller = loggersByKey.first(where: { $0.value.client != nil })?.value,
              let client = controller.client as? AWSCloudWatchLogs.CloudWatchLogsClient else {
            throw CloudWatchLoggingError.configuration(
                "No CloudWatch Logs client found",
                "Ensure a logger has been created and the client is configured."
            )
        }
        return client
    }

    // MARK: - Private

    private func getOrCreateController(namespace: String, logLevel: LogLevel) -> CloudWatchLoggingSessionController {
        let key = LoggerKey(namespace: namespace, logLevel: logLevel)
        if let existing = loggersByKey[key] {
            return existing
        }
        return lock.execute {
            if let existing = loggersByKey[key] {
                return existing
            }
            let controller = CloudWatchLoggingSessionController(
                credentialIdentityResolver: credentialIdentityResolver,
                logFilter: self.logFilter,
                namespace: namespace,
                logLevel: logLevel,
                logGroupName: self.logGroupName,
                region: self.region,
                localStoreMaxSizeInMB: self.localStoreMaxSizeInMB,
                userIdentifier: self.userIdentifier,
                networkMonitor: self.networkMonitor,
                eventSubject: self.eventSubject,
                configureClient: self.configureClient
            )
            if enabled {
                controller.enable()
            }
            loggersByKey[key] = controller
            return controller
        }
    }

    func reset() async {
        lock.execute {
            loggersByKey = [:]
        }
    }

    // MARK: - User Identity

    /// Set the current user identifier. Affects log stream naming and
    /// user-specific log level filtering. Pass `nil` on sign-out.
    public func setUserIdentifier(_ identifier: String?) {
        userIdentifier = identifier
        updateSessionControllers()
    }

    /// Update the logging constraints. Affects log level filtering for all namespaces.
    public func setLoggingConstraints(_ constraints: LoggingConstraints) {
        logFilter.loggingConstraints = constraints
    }

    private func updateSessionControllers() {
        lock.execute {
            for controller in loggersByKey.values {
                controller.setCurrentUser(identifier: self.userIdentifier)
            }
        }
    }
}

// MARK: - NSLock helper

private extension NSLock {
    @discardableResult
    func execute<T>(_ block: () -> T) -> T {
        lock()
        defer { unlock() }
        return block()
    }
}

// MARK: - CloudWatchLoggingMonitorDelegate

@available(iOS 13.0, macOS 12.0, tvOS 13.0, watchOS 9.0, *)
extension AmplifyCloudWatchLoggingClient: CloudWatchLoggingMonitorDelegate {
    package func handleAutomaticFlushIntervalEvent() {
        Task {
            try await flushLogs()
        }
    }
}
