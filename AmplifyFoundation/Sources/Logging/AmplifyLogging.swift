//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public final class AmplifyLogging {

    /// Synchronize access to the log sinks
    static let concurrencyQueue = DispatchQueue(label: "com.amplify.foundation.AmplifyLogging")
    static var registeredLogSinks: [String: any LogSinkBehavior] = [:]

    private init() {}

    public static func addSink(_ logSink: any LogSinkBehavior) {
        return concurrencyQueue.sync {
            Self.registeredLogSinks[logSink.id] = logSink
        }
    }

    static func removeSink(_ logSink: any LogSinkBehavior) {
        return concurrencyQueue.sync {
            Self.registeredLogSinks.removeValue(forKey: logSink.id)
        }
    }

    public static func logger(for name: String) -> Logger {
        return concurrencyQueue.sync {
            BroadcastLogger(name: name, sinks: Array(registeredLogSinks.values))
        }
    }

    public static func logger<T>(for type: T.Type) -> Logger {
        return logger(for: String(describing: type))
    }
}
