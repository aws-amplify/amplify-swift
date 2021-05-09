//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Log levels are modeled as Ints to allow for easy comparison of levels
public enum LogLevel: Int {

    /// <#Description#>
    case error

    /// <#Description#>
    case warn

    /// <#Description#>
    case info

    /// <#Description#>
    case debug

    /// <#Description#>
    case verbose
}

extension LogLevel: Comparable {

    /// <#Description#>
    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
