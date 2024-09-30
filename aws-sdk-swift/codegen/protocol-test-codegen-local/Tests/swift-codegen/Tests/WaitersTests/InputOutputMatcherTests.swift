//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Waiters
@testable import SmithyWaitersAPI

class InputOutputMatcherTests: XCTestCase {

    // JMESPath expression: input.stringProperty == output.stringProperty
    // JMESPath comparator: booleanEquals
    // JMESPath expected value: true

    // inputOutput tests are just on the input & output properties, because all the other logic
    // in them is shared with output matchers, which are tested more comprehensively.

    func test_inputOutput_acceptorMatchesWhenInputAndOutputPropertiesMatch() async throws {
        let value = UUID().uuidString
        let input = GetWidgetInput(stringProperty: value)
        let output = GetWidgetOutput(stringProperty: value)
        let subject = try WaitersClient.inputOutputPropertyMatcherWaiterConfig().acceptors[0]
        let match = subject.evaluate(input: input, result: .success(output))
        XCTAssertEqual(match, .success(.success(output)))
    }

    func test_inputOutput_acceptorFailsToMatchWhenInputAndOutputPropertiesDontMatch() async throws {
        let value = UUID().uuidString
        let input = GetWidgetInput(stringProperty: value)
        let output = GetWidgetOutput(stringProperty: value + "xxx")
        let subject = try WaitersClient.inputOutputPropertyMatcherWaiterConfig().acceptors[0]
        let match = subject.evaluate(input: input, result: .success(output))
        XCTAssertNil(match)
    }
}

