//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@dynamicMemberLookup
class Mock {
    var calls: [String: Int] = [:]
    func methodCalled(_ methodName: String) {
        let currentCalls = calls[methodName] ?? 0
        calls[methodName] = currentCalls + 1
    }

    subscript(dynamicMember value: String) -> Int {
        let key = String(value.dropLast("CalledTimes".count))
        return calls[key] ?? 0
    }

    func reset() {
        calls = [:]
    }
}
