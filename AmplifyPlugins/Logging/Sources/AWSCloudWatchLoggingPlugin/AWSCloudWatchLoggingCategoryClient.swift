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

/// Concrete implementation of
/// [LoggingCategoryClientBehavior](x-source-tag://LoggingCategoryClientBehavior)
/// ensures the right log files and cloud watch streams are used according to
/// the application's authentication state.
///
/// - Tag: CloudWatchLoggingCategoryClient
final class AWSCloudWatchLoggingCategoryClient {
    private var _enable: Bool = true

    private let lock = NSLock()
    private let logGroupName: String
    private let region: String
    private let credentialsProvider: CredentialsProvider
    private let authentication: AuthCategoryUserBehavior
    private var loggersByKey: [LoggerKey: AWSCloudWatchLoggingSessionController] = [:]
    private let localStoreMaxSizeInMB: Int
    private var automaticFlushLogMonitor: AWSCLoudWatchLoggingMonitor?
    private let logFilter: AWSCloudWatchLoggingFilterBehavior
    
    /// - Tag: CloudWatchLoggingCategoryClient.init
    init(
        enable: Bool,
        credentialsProvider: CredentialsProvider,
        authentication: AuthCategoryUserBehavior,
        loggingConstraintsResolver: AWSCloudWatchLoggingConstraintsResolver,
        logGroupName: String,
        region: String,
        localStoreMaxSizeInMB: Int,
        flushIntervalInSeconds: Int
    ) {
        self._enable = enable
        self.credentialsProvider = credentialsProvider
        self.authentication = authentication
        self.logGroupName = logGroupName
        self.region = region
        self.localStoreMaxSizeInMB = localStoreMaxSizeInMB
        self.logFilter = AWSCloudWatchLoggingFilter(loggingConstraintsResolver: loggingConstraintsResolver)
        self.automaticFlushLogMonitor = AWSCLoudWatchLoggingMonitor(flushIntervalInSeconds: TimeInterval(flushIntervalInSeconds), eventDelegate: self)
        
    }
    
    func takeUserIdentifierFromCurrentUser() {
        lock.execute {
            for controller in loggersByKey.values {
                controller.takeUserIdentifierFromCurrentUser()
            }
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
        _enable = true
        lock.execute {
            for controller in loggersByKey.values {
                controller.enable()
            }
        }
    }
    
    func disable() {
        _enable = false
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
                                                            localStoreMaxSizeInMB: self.localStoreMaxSizeInMB)
            if _enable {
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
        return self.logger(forCategory: category, namespace: nil, logLevel: Amplify.Logging.logLevel)
    }
    
    func logger(forNamespace namespace: String) -> Logger {
        self.logger(forCategory: namespace)
    }
    
    func logger(forCategory category: String, forNamespace namespace: String) -> Logger {
        self.logger(forCategory: category, namespace: namespace, logLevel: Amplify.Logging.logLevel)
    }
    
    func getInternalClient() -> CloudWatchLogsClientProtocol {
        loggersByKey.first!.value.client!
    }
    
    func flushLogs() async throws {
        guard _enable else { return }
        try await loggersByKey.first?.value.flushLogs()
    }
}

extension AWSCloudWatchLoggingCategoryClient: AWSCloudWatchLoggingMonitorDelegate {
    func handleAutomaticFlushIntervalEvent() {
        Task {
            try await flushLogs()
        }
    }
}
