//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
#if canImport(Combine)
import Combine
#endif

@testable import Amplify
@testable import AmplifyTestCommon

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

#if canImport(Combine)
    func testFastOperationWithPublisher() throws {
        let exp1 = expectation(description: "\(#function)-1")
        let exp2 = expectation(description: "\(#function)-2")
        let input = [1, 2, 3]
        var output: Int = 0
        var thrown: Error? = nil

        let request = FastOperationRequest(numbers: input)
        let publisher = runFastOperationWithPublisher(request: request)

        let sink = publisher.sink { completion in
            switch completion {
            case .failure(let error):
                thrown = error
            case .finished:
                exp1.fulfill()
            }
        } receiveValue: { result in
            output = result.value
            exp2.fulfill()
        }
        defer {
            sink.cancel()
        }

        wait(for: [exp1, exp2], timeout: 5.0)

        XCTAssertEqual(input.sum(), output)
        XCTAssertNil(thrown)
    }
#endif

    /// Given: A operation with discrete steps (10)
    /// When: Its progress sequence is iterated
    /// Then: It reports each step up to a `fractionCompleted` value that represents 100% completion
    func testLongOperation() async throws {
        let request = LongOperationRequest(steps: 10, delay: 0.01)
        let longTask = await runLongOperation(request: request)

        Task {
            var progressCount = 0
            var lastProgress: Double = 0

            await longTask.progress.forEach { progress in
                lastProgress = progress.fractionCompleted
                progressCount += 1
            }
            // The first progress report happens on `fractionCompleted` 0.0
            XCTAssertGreaterThanOrEqual(progressCount, 10)

            // Note that `fractionComleted` is calculated by dividing
            // `completedUnitCount` by `totalUnitCount`. See:
            //https://developer.apple.com/documentation/foundation/progress/1408579-fractioncompleted
            XCTAssertEqual(lastProgress, 1.0, accuracy: 0.1)
        }

        let value = try await longTask.value
        let output = value.id

        XCTAssertNotNil(output)
        XCTAssertFalse(output.isEmpty)
    }

#if canImport(Combine)
    func testLongOperationWithPublishers() async throws {
        let exp1 = expectation(description: "\(#function)-1")
        let exp2 = expectation(description: "\(#function)-2")

        var success = false
        var output: String? = nil
        var thrown: Error? = nil
        var requestID: String? = nil
        var progressCount = 0
        var lastProgress: Double = 0

        let request = LongOperationRequest(steps: 10, delay: 0.01)
        let longTask = await runLongOperation(request: request)

        let progressPublisher = longTask.inProcessPublisher
        let resultPublisher = longTask.resultPublisher

        let progressSink = progressPublisher.sink { completion in
            switch completion {
            case .failure:
                break
            case .finished:
                exp1.fulfill()
            }
        } receiveValue: { progress in
            lastProgress = progress.fractionCompleted
            progressCount += 1
        }
        defer {
            progressSink.cancel()
        }

        let resultSink = resultPublisher.sink { completion in
            switch completion {
            case .failure(let error):
                thrown = error
            case .finished:
                success = true
            }
        } receiveValue: { result in
            output = result.id
            requestID = longTask.requestID
            exp2.fulfill()
        }
        defer {
            resultSink.cancel()
        }

        wait(for: [exp1, exp2], timeout: 10.0)

        XCTAssertGreaterThanOrEqual(progressCount, 10)
        XCTAssertEqual(lastProgress, 1)

        XCTAssertTrue(success)
        XCTAssertNotNil(output)
        XCTAssertFalse(output.isEmpty)
        XCTAssertNil(thrown)
        XCTAssertFalse(requestID.isEmpty)
        XCTAssertEqual(request.requestID, requestID)
    }
#endif

    private func runFastOperation(request: FastOperationRequest) async throws -> FastTask.Success {
        let operation = FastOperation(request: request)
        let taskAdapter = AmplifyOperationTaskAdapter(operation: operation)
        queue.addOperation(operation)
        return try await taskAdapter.value
    }

    private func runLongOperation(request: LongOperationRequest) async -> LongTask {
        let operation = LongOperation(request: request)
        let taskAdapter = AmplifyInProcessReportingOperationTaskAdapter(operation: operation)
        queue.addOperation(operation)
        return taskAdapter
    }

    private func runFastOperationWithPublisher(request: FastOperationRequest) -> FastResultPublisher {
        let operation = FastOperation(request: request)
        let taskAdapter = AmplifyOperationTaskAdapter(operation: operation)
        let resultPublisher = taskAdapter.resultPublisher
        queue.addOperation(operation)
        return resultPublisher
    }

}
