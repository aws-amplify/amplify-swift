//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon

extension Sequence where Element: SignedInteger {
    @inlinable func sum() -> Element {
        reduce(0, +)
    }
}

extension Sequence where Element: UnsignedInteger {
    @inlinable func sum() -> Element {
        reduce(0, +)
    }
}

class AmplifyTaskTests: XCTestCase {
    let queue = OperationQueue()

    func testFastOperation() async throws {
        let input = [1, 2, 3]
        var output: Int = 0
        var thrown: Error? = nil

        do {
            let request = FastOperationRequest(numbers: input)
            let result = try await runFastOperation(request: request)
            output = result.value
        } catch {
            thrown = error
        }

        XCTAssertEqual(input.sum(), output)
        XCTAssertNil(thrown)
    }

    func testLongOperation() async throws {
        var success = false
        var output: String? = nil
        var thrown: Error? = nil

        let request = LongOperationRequest(steps: 10, delay: 0.1)
        let longTask = await runLongOperation(request: request)

        Task {
            var progressCount = 0
            var lastProgress: Double = 0

            let sequence = await longTask.progress
            for await progress in sequence {
                lastProgress = progress.fractionCompleted
                progressCount += 1
            }

            XCTAssertEqual(progressCount, 11)
            XCTAssertEqual(lastProgress, 100)
        }

        do {
            let result = try await longTask.result
            output = result.id
            success = true
        } catch {
            thrown = error
        }

        XCTAssertTrue(success)
        XCTAssertNotNil(output)
        XCTAssertFalse(output.isEmpty)
        XCTAssertNil(thrown)
    }

    private func runFastOperation(request: FastOperationRequest) async throws -> FastTask.Success {
        let operation = FastOperation(request: request)
        let taskAdapter = AmplifyOperationTaskAdapter(operation: operation)
        queue.addOperation(operation)
        return try await taskAdapter.result
    }

    private func runLongOperation(request: LongOperationRequest) async -> LongTask {
        let operation = LongOperation(request: request)
        let taskAdapter = AmplifyInProcessReportingOperationTaskAdapter(operation: operation)
        queue.addOperation(operation)
        return taskAdapter
    }

}
