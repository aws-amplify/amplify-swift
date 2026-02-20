//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Protocol to implement to send log messages to a specific destination
/// For example, logging to the console or a custom logging framework
public protocol LogSinkBehavior: Identifiable {
    /// A unique identifier for a log sink
    var id: String { get }
    
    /// Returns true if this sink will emit logs at the given level
    func isEnabled(for logLevel: LogLevel) -> Bool
    
    /// Emit the given log message
    func emit(message: LogMessage)
}
