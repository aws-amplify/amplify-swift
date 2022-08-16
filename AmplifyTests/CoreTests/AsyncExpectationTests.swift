//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import Amplify
@testable import AmplifyTestCommon

final class AsyncExpectationTests: XCTestCase {

    func testDoneExpectation() async throws {
        let done = AsyncExpectation.expectation(description: "done")
        Task {
            try await Task.sleep(seconds: 0.01)
            await done.fulfill()
        }
        try await AsyncExpectation.waitForExpectations([done])
    }

    func testDoneMultipleTimesExpectation() async throws {
        let done = AsyncExpectation.expectation(description: "done", expectedFulfillmentCount: 3)
        Task {
            try await Task.sleep(seconds: 0.01)
            await done.fulfill()
        }
        Task {
            try await Task.sleep(seconds: 0.01)
            await done.fulfill()
        }
        Task {
            try await Task.sleep(seconds: 0.01)
            await done.fulfill()
        }
        try await AsyncExpectation.waitForExpectations([done])
    }

    func testNotDoneInvertedExpectation() async throws {
        let notDone = AsyncExpectation.expectation(description: "not done", isInverted: true)
        try await AsyncExpectation.waitForExpectations([notDone], timeout: 0.01)
    }

    func testDoneAndNotDoneInvertedExpectation() async throws {
        let done = AsyncExpectation.expectation(description: "done")
        let notDone = AsyncExpectation.expectation(description: "not done", isInverted: true)
        Task {
            try await Task.sleep(seconds: 0.01)
            await done.fulfill()
        }
        try await AsyncExpectation.waitForExpectations([notDone], timeout: 0.01)
        try await AsyncExpectation.waitForExpectations([done])
    }

    func testMultipleFulfilledExpectation() async throws {
        let one = AsyncExpectation.expectation(description: "one")
        let two = AsyncExpectation.expectation(description: "two")
        let three = AsyncExpectation.expectation(description: "three")
        Task {
            try await Task.sleep(seconds: 0.01)
            await one.fulfill()
        }
        Task {
            try await Task.sleep(seconds: 0.01)
            await two.fulfill()
        }
        Task {
            try await Task.sleep(seconds: 0.01)
            await three.fulfill()
        }
        try await AsyncExpectation.waitForExpectations([one, two, three])
    }

    func testMultipleAlreadyFulfilledExpectation() async throws {
        let one = AsyncExpectation.expectation(description: "one")
        let two = AsyncExpectation.expectation(description: "two")
        let three = AsyncExpectation.expectation(description: "three")
        await one.fulfill()
        await two.fulfill()
        await three.fulfill()

        try await AsyncExpectation.waitForExpectations([one, two, three])
    }
}
