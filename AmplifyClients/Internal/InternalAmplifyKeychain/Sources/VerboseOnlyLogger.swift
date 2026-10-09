//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation

/// Forwards every message to `base` at verbose level.
///
/// For keychain calls whose failure has always been silent and is expected (a best-effort existence
/// check, say). Routing them through a store that logs at error level would add error logs that apps have
/// never seen, so such a store is given this logger instead.
package struct VerboseOnlyLogger: Logger {

    private let base: any Logger

    package init(_ base: any Logger) {
        self.base = base
    }

    package func error(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        base.verbose(message(), error())
    }

    package func warn(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        base.verbose(message(), error())
    }

    package func info(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        base.verbose(message(), error())
    }

    package func debug(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        base.verbose(message(), error())
    }

    package func verbose(_ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        base.verbose(message(), error())
    }

    package func log(_ logLevel: LogLevel, _ message: @autoclosure () -> String, _ error: @autoclosure () -> Error?) {
        guard logLevel != .none else {
            return
        }
        base.verbose(message(), error())
    }
}
