//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import os.log

protocol DefaultLogger {
    static var logger: OSLog { get }
}

class LoggingTimer {
    let log: OSLog
    private var start: Date?
    private var end: Date?

    var duration: TimeInterval {
        guard let start = start?.timeIntervalSince1970 else {
            return 0
        }
        let stop = end?.timeIntervalSince1970 ?? Date().timeIntervalSince1970
        return stop - start
    }

    init(_ name: String) {
        self.log = OSLog(subsystem: "AWSCognitoPlugin", category: name)
    }

    @discardableResult
    func reset() -> LoggingTimer {
        start = nil
        end = nil
        return self
    }

    @discardableResult
    func start(_ message: String) -> LoggingTimer {
        note(message)
        start = start ?? Date()
        return self
    }

    @discardableResult
    func stop(_ message: String) -> LoggingTimer {
        end = end ?? Date()
        note(message)
        return self
    }

    @discardableResult
    func note(_ message: String) -> LoggingTimer {
        os_log(.debug, log: log, "(%03.3f) %{public}s", duration, message)
        return self
    }

}

extension LoggingTimer {
    convenience init(_ logger: DefaultLogger) {
        let category = type(of: logger).category
        self.init(category)
    }
}

extension DefaultLogger {
    static var category: String {
        String(describing: self)
    }

    static var logger: OSLog {
        OSLog(subsystem: "AWSCognitoPlugin", category: String(describing: self))
    }
}

