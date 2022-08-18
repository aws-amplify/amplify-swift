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

class AmplifyPublisherTests: XCTestCase {
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
        
        let sink = Amplify.Publisher.create {
            try await self.getOutput(input: input)
        }
            .sink { completion in
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
        
        let sink = Amplify.Publisher.create {
            try await self.getOutput(input: input)
        }
            .sink { completion in
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

    func testAsyncPassthroughSubjectCancellation() async throws {
        let noCompletion = AsyncExpectation.expectation(description: "noCompletion", isInverted: true)
        let noValueReceived = AsyncExpectation.expectation(description: "noValueReceived", isInverted: true)
        let input = 7
        var output: Int = 0
        var success = false
        var thrown: Error? = nil
        
        let sink = Amplify.Publisher.create {
            try await self.getOutput(input: input, seconds: 0.25)
        }
            .sink { completion in
                switch completion {
                case .finished:
                    success = true
                case .failure(let error):
                    thrown = error
                }
                Task {
                    await noCompletion.fulfill()
                }
            } receiveValue: { value in
                output = value
                Task {
                    await noValueReceived.fulfill()
                }
        }

        // cancel immediately
        sink.cancel()

        try await AsyncExpectation.waitForExpectations([noCompletion, noValueReceived], timeout: 0.01)

        // completion and value are not expected when sink is cancelled
        XCTAssertNotEqual(input, output)
        XCTAssertFalse(success)
        XCTAssertNil(thrown)
    }

    func getOutput(input: Int, seconds: Double = 0.0) async throws -> Int {
        try await Task.sleep(seconds: seconds)
        try Task.checkCancellation()
        guard input != 13 else { throw Failure.unluckyNumber }
        return input
    }
}
#endif
