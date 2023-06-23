//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify

// As expected, running this work as straight up Task invocations:

// ```
// try await Task {
//     try await Task.sleep(nanoseconds: 1)
//     expectation1.fulfill()
// }
// try await Task {
//     try await Task.sleep(nanoseconds: 1)
//     expectation2.fulfill()
// }
// try await Task {
//     try await Task.sleep(nanoseconds: 1)
//     expectation3.fulfill()
// }
// await fulfillment(of: [expectation1, expectation2, expectation3], enforceOrder: true)
// ```
//
// does not guarantee order of execution. TaskQueue is intended to serialize execution to guarantee
// that the in-process task completes before the new one is executed.

final class AmplifyTaskQueueTests: XCTestCase {
    func testSync() async throws {
        for _ in 1 ... 1_000 {
            try await doSyncTest()
        }
    }

    func addSync(expectation: XCTestExpectation, to taskQueue: TaskQueue<Void>) async throws {
        try await taskQueue.sync {
            try await Task.sleep(nanoseconds: 1)
            expectation.fulfill()
        }
    }

    func doSyncTest() async throws {
        let expectation1 = expectation(description: "expectation1")
        let expectation2 = expectation(description: "expectation2")
        let expectation3 = expectation(description: "expectation3")

        let tq = TaskQueue<Void>()
        try await addSync(expectation: expectation1, to: tq)
        try await addSync(expectation: expectation2, to: tq)
        try await addSync(expectation: expectation3, to: tq)

        await fulfillment(of: [expectation1, expectation2, expectation3], enforceOrder: true)
    }

}
