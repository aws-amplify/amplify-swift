//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// A struct representing a single log message
public struct LogMessage {
    
    let level: LogLevel
    let name: String
    let content: String
    let error: Error?
    
    public init(level: LogLevel, name: String, content: String, error: Error? = nil) {
        self.level = level
        self.name = name
        self.content = content
        self.error = error
    }
}
