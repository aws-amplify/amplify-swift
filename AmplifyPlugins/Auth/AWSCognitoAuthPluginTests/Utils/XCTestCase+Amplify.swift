//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

extension XCTestCase {
    func wait(for duration: TimeInterval) {
        let expectation = expectation(description: "Sleep for \(duration) seconds")
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: DispatchTime.now() + duration) {
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: duration + 0.5)
    }
}
