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
import Network
import SmithyIdentity

/// Concrete implementation of
/// [LoggingCategoryClientBehavior](x-source-tag://LoggingCategoryClientBehavior)
/// ensures the right log files and cloud watch streams are used according to
/// the application's authentication state.
///
/// - Tag: CloudWatchLoggingCategoryClient
/// - Note: `@unchecked Sendable`: the client starts detached tasks that touch its state, so every
///   access to `_enabled`, `loggersByKey` and `userIdentifier` goes through `lock`. Members that already
///   hold the lock read the underscored storage directly, because `NSLock` is not recursive.
final class AWSCloudWatchLoggingCategoryClient: @unchecked Sendable {

    /// Guarded by `lock`. Read through `isEnabled` from unlocked contexts.
    private var _enabled: Bool = true

    private let lock = NSLock()

    /// `_userIdentifier` for callers that do not already hold `lock`.
    private var currentUserIdentifier: String? { lock.execute { _userIdentifier } }
    private let logGroupName: String
    private let region: String
    private let credentialIdentityResolver: any AWSCredentialIdentityResolver
    private let authentication: AuthCategoryUserBehavior
    private var loggersByKey: [LoggerKey: AWSCloudWatchLoggingSessionController] = [:]
    private let localStoreMaxSizeInMB: Int
    private var automaticFlushLogMonitor: AWSCLoudWatchLoggingMonitor?
    private let logFilter: AWSCloudWatchLoggingFilterBehavior
    /// Guarded by `lock`. Read through `currentUserIdentifier` from unlocked contexts.
    private var _userIdentifier: String?
    private var authSubscription: AnyCancellable? { willSet { authSubscription?.cancel() } }
    private let networkMonitor: LoggingNetworkMonitor

    init(
        enable: Bool,
        credentialIdentityResolver: some AWSCredentialIdentityResolver,
        authentication: AuthCategoryUserBehavior,
        loggingConstraintsResolver: AWSCloudWatchLoggingConstraintsResolver,
        logGroupName: String,
        region: String,
        localStoreMaxSizeInMB: Int,
        flushIntervalInSeconds: Int,
        networkMonitor: LoggingNetworkMonitor = NWPathMonitor()
    ) {
        self._enabled = enable
        self.credentialIdentityResolver = credentialIdentityResolver
        self.authentication = authentication
        self.logGroupName = logGroupName
        self.region = region
        self.localStoreMaxSizeInMB = localStoreMaxSizeInMB
        self.logFilter = AWSCloudWatchLoggingFilter(loggingConstraintsResolver: loggingConstraintsResolver)
        self.networkMonitor = networkMonitor
        self.networkMonitor.startMonitoring(using: DispatchQueue(label: "com.amazonaws.awscloudwatchlogging.networkmonitor"))
        self.automaticFlushLogMonitor = AWSCLoudWatchLoggingMonitor(flushIntervalInSeconds: TimeInterval(flushIntervalInSeconds), eventDelegate: self)
        automaticFlushLogMonitor?.setAutomaticFlushIntervals()
        self.authSubscription = Amplify.Hub.publisher(for: .auth).sink { [weak self] payload in
            self?.handle(payload: payload)
        }
    }

    func takeUserIdentifierFromCurrentUser() {
        Task {
            do {
                let user = try await authentication.getCurrentUser()
                self.lock.execute { self._userIdentifier = user.userId }
            } catch {
                self.lock.execute { self._userIdentifier = nil }
            }
            self.updateSessionControllers()
        }
    }

    private func updateSessionControllers() {
        lock.execute {
            for controller in loggersByKey.values {
                controller.setCurrentUser(identifier: self._userIdentifier)
            }
        }
    }

    private func handle(payload: HubPayload) {
        enum CognitoEventName: String {
            case signInAPI = "Auth.signInAPI"
            case signOutAPI = "Auth.signOutAPI"
            case configured = "InternalConfigureAuth"
        }
        switch payload.eventName {
        case HubPayload.EventName.Auth.signedIn, CognitoEventName.signInAPI.rawValue, CognitoEventName.configured.rawValue:
            takeUserIdentifierFromCurrentUser()
        case HubPayload.EventName.Auth.signedOut, CognitoEventName.signOutAPI.rawValue:
            lock.execute { _userIdentifier = nil }
            updateSessionControllers()
        default:
            break
        }
    }

    /// - Tag: CloudWatchLoggingCategoryClient.reset
    func reset() async {
        lock.execute {
            loggersByKey = [:]
        }
    }

    func getLoggerSessionController(forCategory category: String, logLevel: LogLevel) -> AWSCloudWatchLoggingSessionController? {
        let key = LoggerKey(category: category, logLevel: logLevel)
        return lock.execute { loggersByKey[key] }
    }
}

extension AWSCloudWatchLoggingCategoryClient: LoggingCategoryClientBehavior {
    func enable() {
        lock.execute {
            _enabled = true
            for controller in loggersByKey.values {
                controller.enable()
            }
        }
    }

    func disable() {
        lock.execute {
            _enabled = false
            for controller in loggersByKey.values {
                controller.disable()
            }
        }
    }

    var `default`: Logger {
        return logger(forCategory: "Amplify")
    }

    func logger(forCategory category: String, namespace: String?, logLevel: Amplify.LogLevel) -> Logger {
        return lock.execute {
            let key = LoggerKey(category: category, logLevel: logLevel)
            if let existing = loggersByKey[key] {
                return existing
            }

            let controller = AWSCloudWatchLoggingSessionController(
                credentialIdentityResolver: credentialIdentityResolver,
                authentication: authentication,
                logFilter: self.logFilter,
                category: category,
                namespace: namespace,
                logLevel: logLevel,
                logGroupName: self.logGroupName,
                region: self.region,
                localStoreMaxSizeInMB: self.localStoreMaxSizeInMB,
                userIdentifier: self._userIdentifier,
                networkMonitor: self.networkMonitor
            )
            if _enabled {
                controller.enable()
            }
            loggersByKey[key] = controller
            return controller
        }
    }

    func logger(forCategory category: String, logLevel: LogLevel) -> Logger {
        return logger(forCategory: category, namespace: nil, logLevel: logLevel)
    }

    func logger(forCategory category: String) -> Logger {
        let defaultLogLevel = logFilter.getDefaultLogLevel(forCategory: category, userIdentifier: currentUserIdentifier)
        return logger(forCategory: category, namespace: nil, logLevel: defaultLogLevel)
    }

    func logger(forNamespace namespace: String) -> Logger {
        logger(forCategory: namespace)
    }

    func logger(forCategory category: String, forNamespace namespace: String) -> Logger {
        let defaultLogLevel = logFilter.getDefaultLogLevel(forCategory: category, userIdentifier: currentUserIdentifier)
        return logger(forCategory: category, namespace: namespace, logLevel: defaultLogLevel)
    }

    func getInternalClient() -> CloudWatchLogsClientProtocol {
        guard let client = lock.execute({ loggersByKey.first(where: { $0.value.client != nil })?.value.client }) else {
            return Fatal.preconditionFailure(
                """
                AWSCloudWatchLoggingPlugin is missing an internal AWS CloudWatch client.  Ensure that
                the AWSCloudWatchLoggingPlugin is configured.
                """
            )
        }
        return client
    }

    /// Snapshots the controllers under the lock, then flushes outside it.
    ///
    /// This runs on a repeating background timer, so iterating `loggersByKey` directly raced every
    /// insertion made under the lock by `logger(forCategory:namespace:logLevel:)`. Awaiting while holding
    /// the lock is not an option either, hence the snapshot.
    func flushLogs() async throws {
        let controllers: [AWSCloudWatchLoggingSessionController] = lock.execute {
            guard _enabled else { return [] }
            return Array(loggersByKey.values)
        }
        for logger in controllers {
            try await logger.flushLogs()
        }
    }
}

extension AWSCloudWatchLoggingCategoryClient: AWSCloudWatchLoggingMonitorDelegate {
    func handleAutomaticFlushIntervalEvent() {
        Task {
            try await flushLogs()
        }
    }
}
