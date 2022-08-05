//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import Amplify

// These tests must be run with ThreadSanitizer enabled
class ChildTaskTests: XCTestCase {

    func testFastOperationWithMultipleAwaits() async throws {
        let input = [1, 2, 3]
        let request = FastOperationRequest(numbers: input)
        let queue = OperationQueue()
        let operation = FastOperation(request: request)
        let childTask: ChildTask<Void, FastOperation.Success, FastOperation.Failure> = ChildTask(parent: operation)
        let token = operation.subscribe { result in
            Task {
                await childTask.finish(result)
            }
        }
        defer {
            Amplify.Hub.removeListener(token)
        }

        let expectedOutput = input.sum()

        let task1 = Task {
            try await childTask.result.value
        }
        let task2 = Task {
            try await childTask.result.value
        }
        let task3 = Task {
            try await childTask.result.value
        }

        queue.addOperation(operation)

        let output1 = try await task1.value
        let output2 = try await task2.value
        let output3 = try await task3.value

        XCTAssertEqual(output1, expectedOutput)
        XCTAssertEqual(output2, expectedOutput)
        XCTAssertEqual(output3, expectedOutput)
    }

}
