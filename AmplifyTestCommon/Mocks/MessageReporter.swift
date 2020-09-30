//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify

class MessageReporter {
    /// Callbacks to be invoked
    var listeners = AtomicValue<[(String) -> Void]>(initialValue: [])

    func notify(_ message: String = #function) {
        listeners.get().forEach { $0(message) }
    }

    init() {
        notify()
    }
}
