//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(Combine)
import XCTest
import Combine

@testable import Amplify
@testable import AmplifyTestCommon

class AsyncPassthroughSubjectTests: XCTestCase {
    enum Failure: Error {
        case unluckyNumber
    }
    func testAsyncPassthroughSubjectSuccess() async throws {
        let notDone = AsyncExpectation.expectation(description: "notDone", isInverted: true)
        let done = AsyncExpectation.expectation(description: "done")
        let input = 7
        var output: Int = 0
        var success = false
        var thrown: Error? = nil

        let subject = AsyncPassthroughSubject {
            try await self.getOutput(input: input)
        }
        let publisher = subject.eraseToAnyPublisher()
        let sink = publisher.sink { completion in
            switch completion {
            case .finished:
                success = true
            case .failure(let error):
                thrown = error
                Task {
                    await notDone.fulfill()
                }
            }
            Task {
                await done.fulfill()
            }
        } receiveValue: { value in
            output = value
        }

        try await AsyncExpectation.waitForExpectations([notDone], timeout: 0.01)
        try await AsyncExpectation.waitForExpectations([done])

        XCTAssertEqual(input, output)
        XCTAssertTrue(success)
        XCTAssertNil(thrown)

        sink.cancel()
    }

    func testAsyncPassthroughSubjectFail() async throws {
        let failed = AsyncExpectation.expectation(description: "failed")
        let done = AsyncExpectation.expectation(description: "done")
        let input = 13
        var output: Int = 0
        var success = false
        var thrown: Error? = nil

        let subject = AsyncPassthroughSubject {
            try await self.getOutput(input: input)
        }
        let publisher = subject.eraseToAnyPublisher()
        let sink = publisher.sink { completion in
            switch completion {
            case .finished:
                success = true
            case .failure(let error):
                thrown = error
                Task {
                    await failed.fulfill()
                }
            }
            Task {
                await done.fulfill()
            }
        } receiveValue: { value in
            output = value
        }

        try await AsyncExpectation.waitForExpectations([failed])
        try await AsyncExpectation.waitForExpectations([done])

        XCTAssertNotEqual(input, output)
        XCTAssertFalse(success)
        XCTAssertNotNil(thrown)

        sink.cancel()
    }

    func getOutput(input: Int) async throws -> Int {
        guard input != 13 else { throw Failure.unluckyNumber }
        return input
    }
}
#endif
