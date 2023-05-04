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
    class Worker: Cancellable {
        var cancelCount = 0
        func cancel() {
            cancelCount += 1
        }
    }

    /// Given: A ChildTask instance associated to a fast operation
    /// When: Multiple `Task` instances are created to wait for its results
    /// Then: All `Task` instances receive the exact-same `value`
    func testFastOperationWithMultipleAwaits() async throws {
        let input = [1, 2, 3]
        let request = FastOperationRequest(numbers: input)
        let queue = OperationQueue()
        let operation = FastOperation(request: request)
        let childTask: ChildTask<Void, FastOperation.Success, FastOperation.Failure> = ChildTask(parent: operation)
        let progressSequence = await childTask.inProcess
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
            try await childTask.value.value
        }
        let task2 = Task {
            try await childTask.value.value
        }
        let task3 = Task {
            try await childTask.value.value
        }

        queue.addOperation(operation)

        let output1 = try await task1.value
        let output2 = try await task2.value
        let output3 = try await task3.value

        XCTAssertEqual(output1, expectedOutput)
        XCTAssertEqual(output2, expectedOutput)
        XCTAssertEqual(output3, expectedOutput)

        // Ensure the channel's AsyncSequence does not block after completion
        for await _ in progressSequence {
            XCTFail("Unexpected channel iteration since task has completed.")
        }
    }

    func testChildTaskResultCancelled() async throws {
        let worker = Worker()
        let childTask: ChildTask<Void, String, Never> = ChildTask(parent: worker)
        let progressSequence = await childTask.inProcess
        let cancelExp = expectation(description: "cancel")
        cancelExp.isInverted = true

        let task = Task {
            var thrown: Error? = nil
            do {
                _ = try await childTask.value
                cancelExp.fulfill()
            } catch {
                thrown = error
            }

            XCTAssertNotNil(thrown)
            XCTAssertTrue(thrown is CancellationError)
        }

        await waitForExpectations(timeout: 0.01)
        task.cancel()

        // Ensure the channel's AsyncSequence does not block after completion
        for await _ in progressSequence {
            XCTFail("Unexpected channel iteration since task was cancelled.")
        }
    }

    func testChildTaskResultAlreadyCancelled() async throws {
        let worker = Worker()
        let childTask: ChildTask<Void, String, Never> = ChildTask(parent: worker)
        let progressSequence = await childTask.inProcess
        let cancelExp = expectation(description: "cancel")
        cancelExp.isInverted = true

        await childTask.cancel()
        Task {
            var thrown: Error? = nil
            do {
                _ = try await childTask.value
                cancelExp.fulfill()
            } catch {
                thrown = error
            }

            XCTAssertNotNil(thrown)
            XCTAssertTrue(thrown is CancellationError)
        }

        await waitForExpectations(timeout: 0.01)

        // Ensure the channel's AsyncSequence does not block after completion
        for await _ in progressSequence {
            XCTFail("Unexpected channel iteration since task was cancelled.")
        }
    }

}
