//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import os

struct AppSyncLogger {

    static func error(_ log: String) {
        if #available(iOS 10.0, *) {
            os_log("%@", type: .error, log)
        } else {
            NSLog("%@", log)
        }
    }

    static func debug(_ log: String) {
        if #available(iOS 10.0, *) {
            os_log("%@", type: .debug, log)
        } else {
            NSLog("%@", log)
        }
    }

    static func verbose(_ log: String) {
        if #available(iOS 10.0, *) {
            os_log("%@", type: .debug, log)
        } else {
            NSLog("%@", log)
        }
    }

    static func info(_ log: String) {
        if #available(iOS 10.0, *) {
            os_log("%@", type: .info, log)
        } else {
            NSLog("%@", log)
        }
    }

    static func warn(_ log: String) {
        if #available(iOS 10.0, *) {
            os_log("%@", type: .info, log)
        } else {
            NSLog("%@", log)
        }
    }
    static func error(_ error: Error) {
        if #available(iOS 10.0, *) {
            os_log("%@", type: .error, error.localizedDescription)
        } else {
            NSLog("%@", error.localizedDescription)
        }
    }
}
