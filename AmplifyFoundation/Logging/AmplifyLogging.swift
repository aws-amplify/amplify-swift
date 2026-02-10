//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public final class AmplifyLogging {
    
    /// Synchronize access to the log sinks
    private static let concurrencyQueue = DispatchQueue(label: "com.amplify.foundation.AmplifyLogging")
    private static var registeredLogSinks: [any LogSinkBehavior] = []
    
    public static func addSink(_ logSink: any LogSinkBehavior) {
        return Self.concurrencyQueue.sync {
            Self.registeredLogSinks.append(logSink)
        }
    }
    
    static func removeSink(_ logSink: any LogSinkBehavior) {
        return Self.concurrencyQueue.sync {
            guard let index = registeredLogSinks.firstIndex(where: { $0.id == logSink.id }) else {
                return
            }
            Self.registeredLogSinks.remove(at: index)
        }
    }
    
    public static func logger(for name: String) -> Logger {
        BroadcastLogger(name: name, sinks: registeredLogSinks)
    }
}
