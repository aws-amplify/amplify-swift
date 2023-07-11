//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPluginsCore
import Amplify
import Combine
import Foundation
import AWSCloudWatchLogs
import AWSClientRuntime
import Network

/// Concrete implementation of
/// [LoggingCategoryClientBehavior](x-source-tag://LoggingCategoryClientBehavior)
/// ensures the right log files and cloud watch streams are used according to
/// the application's authentication state.
///
/// - Tag: CloudWatchLoggingCategoryClient
final class AWSCloudWatchLoggingCategoryClient {

    private var enabled: Bool = true

    private let lock = NSLock()
    private let logGroupName: String
    private let region: String
    private let credentialsProvider: CredentialsProvider
    private let authentication: AuthCategoryUserBehavior
    private var loggersByKey: [LoggerKey: AWSCloudWatchLoggingSessionController] = [:]
    private let localStoreMaxSizeInMB: Int
    private var automaticFlushLogMonitor: AWSCLoudWatchLoggingMonitor?
    private let logFilter: AWSCloudWatchLoggingFilterBehavior
    private var userIdentifier: String?
    private var authSubscription: AnyCancellable? { willSet { authSubscription?.cancel() } }
    private let networkMonitor: LoggingNetworkMonitor
    
    init(
        enable: Bool,
        credentialsProvider: CredentialsProvider,
        authentication: AuthCategoryUserBehavior,
        loggingConstraintsResolver: AWSCloudWatchLoggingConstraintsResolver,
        logGroupName: String,
        region: String,
        localStoreMaxSizeInMB: Int,
        flushIntervalInSeconds: Int,
        networkMonitor: LoggingNetworkMonitor = NWPathMonitor()
    ) {
        self.enabled = enable
        self.credentialsProvider = credentialsProvider
        self.authentication = authentication
        self.logGroupName = logGroupName
        self.region = region
        self.localStoreMaxSizeInMB = localStoreMaxSizeInMB
        self.logFilter = AWSCloudWatchLoggingFilter(loggingConstraintsResolver: loggingConstraintsResolver)
        self.networkMonitor = networkMonitor
        self.networkMonitor.startMonitoring(using: DispatchQueue(label: "com.amazonaws.awscloudwatchlogging.networkmonitor"))
        self.automaticFlushLogMonitor = AWSCLoudWatchLoggingMonitor(flushIntervalInSeconds: TimeInterval(flushIntervalInSeconds), eventDelegate: self)
        self.automaticFlushLogMonitor?.setAutomaticFlushIntervals()
        self.authSubscription = Amplify.Hub.publisher(for: .auth).sink { [weak self] payload in
            self?.handle(payload: payload)
        }
    }
    
    func takeUserIdentifierFromCurrentUser() {
        Task {
            do {
                let user = try await authentication.getCurrentUser()
                self.userIdentifier = user.userId
            } catch {
                self.userIdentifier = nil
            }
            self.updateSessionControllers()
        }
    }
    
    private func updateSessionControllers() {
        lock.execute {
            for controller in loggersByKey.values {
                controller.setCurrentUser(identifier: self.userIdentifier)
            }
        }
    }
    
    private func handle(payload: HubPayload) {
        enum CognitoEventName: String {
            case signInAPI = "Auth.signInAPI"
            case signOutAPI = "Auth.signOutAPI"
        }
        switch payload.eventName {
        case HubPayload.EventName.Auth.signedIn, CognitoEventName.signInAPI.rawValue:
            takeUserIdentifierFromCurrentUser()
        case HubPayload.EventName.Auth.signedOut, CognitoEventName.signOutAPI.rawValue:
            self.userIdentifier = nil
            self.updateSessionControllers()
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
}

extension AWSCloudWatchLoggingCategoryClient: LoggingCategoryClientBehavior {
    func enable() {
        enabled = true
        lock.execute {
            for controller in loggersByKey.values {
                controller.enable()
            }
        }
    }
    
    func disable() {
        enabled = false
        lock.execute {
            for controller in loggersByKey.values {
                controller.disable()
            }
        }
    }
    
    var `default`: Logger {
        return self.logger(forCategory: "Amplify")
    }
    
    func logger(forCategory category: String, namespace: String?, logLevel: Amplify.LogLevel) -> Logger {
        return lock.execute {
            let key = LoggerKey(category: category, logLevel: logLevel)
            if let existing = loggersByKey[key] {
                return existing
            }
            
            
            let controller = AWSCloudWatchLoggingSessionController(credentialsProvider: credentialsProvider,
                                                                   authentication: authentication,
                                                                   logFilter: self.logFilter,
                                                                   category: category,
                                                                   namespace: namespace,
                                                                   logLevel: logLevel,
                                                                   logGroupName: self.logGroupName,
                                                                   region: self.region,
                                                                   localStoreMaxSizeInMB: self.localStoreMaxSizeInMB,
                                                                   userIdentifier: self.userIdentifier,
                                                                   networkMonitor: self.networkMonitor)
            if enabled {
                controller.enable()
            }
            loggersByKey[key] = controller
            return controller
        }
    }
    
    func logger(forCategory category: String, logLevel: LogLevel) -> Logger {
        return self.logger(forCategory: category, namespace: nil, logLevel: logLevel)
    }
    
    func logger(forCategory category: String) -> Logger {
        let defaultLogLevel = logFilter.getDefaultLogLevel(forCategory: category, userIdentifier: self.userIdentifier)
        return self.logger(forCategory: category, namespace: nil, logLevel: defaultLogLevel)
    }
    
    func logger(forNamespace namespace: String) -> Logger {
        self.logger(forCategory: namespace)
    }
    
    func logger(forCategory category: String, forNamespace namespace: String) -> Logger {
        let defaultLogLevel = logFilter.getDefaultLogLevel(forCategory: category, userIdentifier: self.userIdentifier)
        return self.logger(forCategory: category, namespace: namespace, logLevel: defaultLogLevel)
    }
    
    func getInternalClient() -> CloudWatchLogsClientProtocol {
        guard let client = loggersByKey.first(where: { $0.value.client != nil })?.value.client else {
            return Fatal.preconditionFailure(
                """
                AWSCloudWatchLoggingPlugin is missing an internal AWS CloudWatch client.  Ensure that
                the AWSCloudWatchLoggingPlugin is configured.
                """
            )
        }
        return client
    }
    
    func flushLogs() async throws {
        guard enabled else { return }
        for logger in loggersByKey.values {
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
