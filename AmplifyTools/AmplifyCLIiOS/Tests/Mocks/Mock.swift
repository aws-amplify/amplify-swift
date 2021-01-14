//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

@dynamicMemberLookup
class Mock {
    private let calledTimesKey = "CalledTimes"
    var calls: [String: Int] = [:]
    func captureCall(_ methodName: String = #function) {
        let currentCalls = calls[methodName] ?? 0
        calls[methodName] = currentCalls + 1
    }

    subscript(dynamicMember value: String) -> Int {
        if !value.contains(calledTimesKey) {
            XCTFail("[Mock] Invalid key provided \(value)")
        }

        let key = String(value.dropLast(calledTimesKey.count))
        return calls[key] ?? 0
    }

    func reset() {
        calls = [:]
    }
}
