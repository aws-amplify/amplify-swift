//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Credit: Dave DeLong
// https://forums.swift.org/t/introducing-namespacing-for-common-swift-error-scenarios/10773

import Foundation

/// An umbrella type supplying static members to handle common
/// and conventional exit scenarios.
public enum Fatal {

    /// Die because a default method must be overriden by a
    /// subtype or extension.
    public static func mustOverride(function: StaticString = #function,
                                    file: StaticString = #file,
                                    line: UInt = #line) -> Never {
        die(reason: "Must be overridden", extra: String(describing: function), file: file, line: line)
    }

    /// Die because this code branch should be unreachable
    public static func unreachable(_ why: String, file: StaticString = #file, line: UInt = #line) -> Never {
        die(reason: "Unreachable", extra: why, file: file, line: line)
    }

    /// Die because this method or function has not yet been implemented.
    ///
    /// - Note: This name takes precedence over `unimplemented` as it
    ///   is clearer and more Swifty
    public static func notImplemented(_ why: String? = nil, file: StaticString = #file, line: UInt = #line) -> Never {
        die(reason: "Not Implemented", extra: why, file: file, line: line)
    }

    /// Die because of a failed assertion. This does not distinguish
    /// between logic conditions (as in `assert`) and user calling
    /// requirements (as in `precondition`)
    public static func require(_ why: String? = nil, file: StaticString = #file, line: UInt = #line) -> Never {
        die(reason: "Assertion failed", extra: why, file: file, line: line)
    }

    /// Die because this TO DO item has not yet been implemented.
    public static func TODO(_ reason: String? = nil, file: StaticString = #file, line: UInt = #line) -> Never {
        die(reason: "Not yet implemented", extra: reason, file: file, line: line)
    }

    /// Provide a `Fatal.error` equivalent to fatalError() to move
    /// Swift standard style away from using `fatalError` directly
    public static func error(_ reason: String? = nil, file: StaticString = #file, line: UInt = #line) -> Never {
        die(reason: "", extra: reason, file: file, line: line)
    }

    /// Performs a diagnostic fatal error with reason and
    /// context information.
    private static func die(reason: String, extra: String?, file: StaticString, line: UInt) -> Never {
        var message = reason
        if let extra = extra {
            message += ": \(extra)"
        }
        fatalError(message, file: file, line: line)
    }

}
