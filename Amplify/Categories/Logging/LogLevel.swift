//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Log levels are modeled as Ints to allow for easy comparison of levels
///
public extension Amplify {
    enum LogLevel: Int {
        case error
        case warn
        case info
        case debug
        case verbose
    }
}
public typealias LogLevel = Amplify.LogLevel

extension LogLevel: Comparable {
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
