//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public final class AmplifyLogging {
    
    /// Synchronize access to the log sinks
    internal static let concurrencyQueue = DispatchQueue(label: "com.amplify.foundation.AmplifyLogging")
    internal static var registeredLogSinks: [String: any LogSinkBehavior] = [:]
    
    public static func addSink(_ logSink: any LogSinkBehavior) {
        return Self.concurrencyQueue.sync {
            Self.registeredLogSinks[logSink.id] = logSink
        }
    }
    
    static func removeSink(_ logSink: any LogSinkBehavior) {
        return Self.concurrencyQueue.sync {
            Self.registeredLogSinks.removeValue(forKey: logSink.id)
        }
    }
    
    public static func logger(for name: String) -> Logger {
        BroadcastLogger(name: name, sinks: Array(registeredLogSinks.values))
    }
}
