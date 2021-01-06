//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Log levels are modeled as Ints to allow for easy comparison of levels
public enum LogLevel: Int {
    case error
    case warn
    case info
    case debug
    case verbose
}

extension LogLevel: Comparable {
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
