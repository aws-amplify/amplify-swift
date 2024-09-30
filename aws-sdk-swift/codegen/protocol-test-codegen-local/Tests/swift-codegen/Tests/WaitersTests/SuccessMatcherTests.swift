//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Waiters
@testable import SmithyWaitersAPI

class SuccessMatcherTests: XCTestCase {

    // MARK: - success matcher

    func test_successTrue_hasSuccessStateWaiter() async throws {
        let waiterConfig = try WaitersClient.successTrueMatcherWaiterConfig()
        let subject = waiterConfig.acceptors[0]
        XCTAssertEqual(subject.state, .success)
    }

    func test_successTrue_acceptorMatchesOnOutput() async throws {
        let output = GetWidgetOutput()
        let subject = try WaitersClient.successTrueMatcherWaiterConfig().acceptors[0]
        let match = subject.evaluate(input: anInput, result: .success(output))
        XCTAssertEqual(match, .success(.success(output)))
    }

    func test_successTrue_acceptorFailsToMatchOnError() async throws {
        let subject = try WaitersClient.successTrueMatcherWaiterConfig().acceptors[0]
        let match = subject.evaluate(input: anInput, result: .failure("boom"))
        XCTAssertNil(match)
    }

    func test_successFalse_acceptorFailsToMatchOnOutput() async throws {
        let output = GetWidgetOutput()
        let subject = try WaitersClient.successFalseMatcherWaiterConfig().acceptors[0]
        let match = subject.evaluate(input: anInput, result: .success(output))
        XCTAssertNil(match)
    }

    func test_successFalse_acceptorMatchesOnError() async throws {
        let error = "boom"
        let subject = try WaitersClient.successFalseMatcherWaiterConfig().acceptors[0]
        let match = subject.evaluate(input: anInput, result: .failure(error))
        XCTAssertEqual(match, .success(.failure(error)))
    }
}

