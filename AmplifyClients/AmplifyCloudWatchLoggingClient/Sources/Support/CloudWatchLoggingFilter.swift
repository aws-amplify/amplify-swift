//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation

/// Provides the concrete implementation for the CloudWatchLoggingFilterBehavior.
final class CloudWatchLoggingFilter: CloudWatchLoggingFilterBehavior, @unchecked Sendable {
    private let lock = NSLock()
    private var _loggingConstraints: LoggingConstraints

    var loggingConstraints: LoggingConstraints {
        get { lock.execute { _loggingConstraints } }
        set { lock.execute { _loggingConstraints = newValue } }
    }

    init(loggingConstraints: LoggingConstraints) {
        self._loggingConstraints = loggingConstraints
    }

    func canLog(withNamespace namespace: String?, logLevel: LogLevel, userIdentifier: String?) -> Bool {
        guard logLevel != .none else { return false }
        let constraints = loggingConstraints
        let loweredCasedNamespace = namespace?.lowercased()

        if let userConstraints = constraints.userLogLevel?.first(where: { $0.key == userIdentifier })?.value {
            if let ns = loweredCasedNamespace,
               let namespaceLogLevel = userConstraints.namespaceLogLevel.first(where: { $0.key.lowercased() == ns })?.value {
                return logLevel.rawValue <= namespaceLogLevel.rawValue && namespaceLogLevel != .none
            }
            return logLevel.rawValue <= userConstraints.defaultLogLevel.rawValue && userConstraints.defaultLogLevel != .none
        }

        if let ns = loweredCasedNamespace,
           let namespaceLogLevel = constraints.namespaceLogLevel?.first(where: { $0.key.lowercased() == ns })?.value {
            return logLevel.rawValue <= namespaceLogLevel.rawValue && namespaceLogLevel != .none
        }

        return logLevel.rawValue <= constraints.defaultLogLevel.rawValue && constraints.defaultLogLevel != .none
    }

    func getDefaultLogLevel(forNamespace namespace: String?, userIdentifier: String?) -> LogLevel {
        let constraints = loggingConstraints
        let loweredCasedNamespace = namespace?.lowercased()

        if let userConstraints = constraints.userLogLevel?.first(where: { $0.key == userIdentifier })?.value {
            if let ns = loweredCasedNamespace,
               let namespaceLogLevel = userConstraints.namespaceLogLevel.first(where: { $0.key.lowercased() == ns })?.value {
                return namespaceLogLevel
            }
            return userConstraints.defaultLogLevel
        }

        if let ns = loweredCasedNamespace,
           let namespaceLogLevel = constraints.namespaceLogLevel?.first(where: { $0.key.lowercased() == ns })?.value {
            return namespaceLogLevel
        }

        return constraints.defaultLogLevel
    }
}

private extension NSLock {
    @discardableResult
    func execute<T>(_ block: () -> T) -> T {
        lock(); defer { unlock() }
        return block()
    }
}
