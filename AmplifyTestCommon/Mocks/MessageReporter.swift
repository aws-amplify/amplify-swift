//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

class MessageReporter {
    /// Callbacks to be invoked
    var listeners = [(String) -> Void]()

    func notify(_ message: String = #function) {
        listeners.forEach { $0(message) }
    }

    init() {
        notify()
    }
}
