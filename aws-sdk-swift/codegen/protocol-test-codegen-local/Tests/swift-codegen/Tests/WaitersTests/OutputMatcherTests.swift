//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime
import XCTest
@testable import Waiters
@testable import SmithyWaitersAPI

class OutputMatcherTests: XCTestCase {

    // MARK: properties & stringEquals comparator

    // JMESPath expression: stringProperty
    // JMESPath comparator: stringEquals
    // JMESPath expected value: payload property contents

    func test_outputStringProperty_acceptorMatchesOnPropertyMatch() async throws {
        let output = GetWidgetOutput(stringProperty: "payload property contents")
        let subject = try WaitersClient.outputStringPropertyMatcherWaiterConfig().acceptors[0]
        let match = subject.evaluate(input: anInput, result: .success(output))
        XCTAssertEqual(match, .success(.success(output)))
    }

    func test_outputStringProperty_acceptorFailsToMatchOnPropertyMismatch() async throws {
        let output = GetWidgetOutput(stringProperty: "not the payload property contents")
        let subject = try WaitersClient.outputStringPropertyMatcherWaiterConfig().acceptors[0]
        let match = subject.evaluate(input: anInput, result: .success(output))
        XCTAssertNil(match)
    }

    func test_outputStringProperty_acceptorFailsToMatchOnNullProperty() async throws {
        let output = GetWidgetOutput(stringProperty: nil)
        let subject = try WaitersClient.outputStringPropertyMatcherWaiterConfig().acceptors[0]
        let match = subject.evaluate(input: anInput, result: .success(output))
        XCTAssertNil(match)
    }

    // MARK: properties & booleanEquals comparator

    // JMESPath expression: booleanProperty
    // JMESPath comparator: booleanEquals
    // JMESPath expected value: false

    func test_outputBooleanProperty_acceptorMatchesOnPropertyMatch() async throws {
        let output = GetWidgetOutput(booleanProperty: false)
        let subject = try WaitersClient.outputBooleanPropertyMatcherWaiterConfig().acceptors[0]
        let match = subject.evaluate(input: anInput, result: .success(output))
        XCTAssertEqual(match, .success(.success(output)))
    }

    func test_outputBooleanProperty_acceptorFailsToMatchOnPropertyMismatch() async throws {
        let output = GetWidgetOutput(booleanProperty: true)
        let subject = try WaitersClient.outputBooleanPropertyMatcherWaiterConfig().acceptors[0]
        let match = subject.evaluate(input: anInput, result: .success(output))
        XCTAssertNil(match)
    }

    func test_outputBooleanProperty_acceptorFailsToMatchOnNullProperty() async throws {
        let output = GetWidgetOutput(booleanProperty: nil)
        let subject = try WaitersClient.outputBooleanPropertyMatcherWaiterConfig().acceptors[0]
        let match = subject.evaluate(input: anInput, result: .success(output))
        XCTAssertNil(match)
    }

    // MARK: properties & allStringEquals comparator

    // JMESPath expression: stringArrayProperty
    // JMESPath comparator: allStringEquals
    // JMESPath expected value: payload property contents

    func test_arrayPropertyAll_acceptorMatchesWhenArrayElementsAllMatch() async throws {
        let expected = "payload property contents"
        let output = GetWidgetOutput(stringArrayProperty: [expected, expected, expected])
        let subject = try WaitersClient.outputStringArrayAllPropertyMatcherWaiterConfig().acceptors[0]
        let match = subject.evaluate(input: anInput, result: .success(output))
        XCTAssertEqual(match, .success(.success(output)))
    }

    func test_arrayPropertyAll_acceptorFailsToMatchWhenArrayElementsDontMatch() async throws {
        let expected = "payload property contents"
        let output = GetWidgetOutput(stringArrayProperty: [expected, expected, "unexpected"])
        let subject = try WaitersClient.outputStringArrayAllPropertyMatcherWaiterConfig().acceptors[0]
        let match = subject.evaluate(input: anInput, result: .success(output))
        XCTAssertNil(match)
    }

    func test_arrayPropertyAll_acceptorFailsToMatchWhenArrayIsEmpty() async throws {
        let output = GetWidgetOutput(stringArrayProperty: [])
        let subject = try WaitersClient.outputStringArrayAllPropertyMatcherWaiterConfig().acceptors[0]
        let match = subject.evaluate(input: anInput, result: .success(output))
        XCTAssertNil(match)
    }

    func test_arrayPropertyAll_acceptorFailsToMatchWhenArrayIsNull() async throws {
        let output = GetWidgetOutput(stringArrayProperty: nil)
        let subject = try WaitersClient.outputStringArrayAllPropertyMatcherWaiterConfig().acceptors[0]
        let match = subject.evaluate(input: anInput, result: .success(output))
        XCTAssertNil(match)
    }

    // MARK: properties & anyStringEquals comparator

    // JMESPath expression: stringArrayProperty
    // JMESPath comparator: anyStringEquals
    // JMESPath expected value: payload property contents

    func test_arrayPropertyAny_acceptorMatchesWhenArrayElementsAllMatch() async throws {
        let expected = "payload property contents"
        let output = GetWidgetOutput(stringArrayProperty: [expected, expected, expected])
        let subject = try WaitersClient.outputStringArrayAnyPropertyMatcherWaiterConfig().acceptors[0]
        let match = subject.evaluate(input: anInput, result: .success(output))
        XCTAssertEqual(match, .success(.success(output)))
    }

    func test_arrayPropertyAny_acceptorMatchesWhenAllButOneElementMismatches() async throws {
        let expected = "payload property contents"
        let output = GetWidgetOutput(stringArrayProperty: [expected, expected, "unexpected"])
        let subject = try WaitersClient.outputStringArrayAnyPropertyMatcherWaiterConfig().acceptors[0]
        let match = subject.evaluate(input: anInput, result: .success(output))
        XCTAssertEqual(match, .success(.success(output)))
    }

    func test_arrayPropertyAny_acceptorFailsToMatchWhenAllElementsMismatch() async throws {
        let unexpected = "unexpected"
        let output = GetWidgetOutput(stringArrayProperty: [unexpected, unexpected, unexpected])
        let subject = try WaitersClient.outputStringArrayAnyPropertyMatcherWaiterConfig().acceptors[0]
        let match = subject.evaluate(input: anInput, result: .success(output))
        XCTAssertNil(match)
    }

    func test_arrayPropertyAny_acceptorFailsToMatchWhenArrayIsEmpty() async throws {
        let output = GetWidgetOutput(stringArrayProperty: [])
        let subject = try WaitersClient.outputStringArrayAnyPropertyMatcherWaiterConfig().acceptors[0]
        let match = subject.evaluate(input: anInput, result: .success(output))
        XCTAssertNil(match)
    }

    func test_arrayPropertyAny_acceptorFailsToMatchWhenArrayIsNull() async throws {
        let output = GetWidgetOutput(stringArrayProperty: nil)
        let subject = try WaitersClient.outputStringArrayAnyPropertyMatcherWaiterConfig().acceptors[0]
        let match = subject.evaluate(input: anInput, result: .success(output))
        XCTAssertNil(match)
    }

    // MARK: - Flatten operator

    // JMESPath expression: children[].grandchildren[].name
    // JMESPath comparator: anyStringEquals
    // JMESPath expected value: expected name

    func test_flatten_acceptorMatchesWhenFlattenedValueMatches() async throws {
        let expected = "expected name"
        let output = outputTree(embeddedName: expected)
        let subject = try WaitersClient.flattenMatcherWaiterConfig().acceptors[0]
        let match = subject.evaluate(input: anInput, result: .success(output))
        XCTAssertEqual(match, .success(.success(output)))
    }

    func test_flatten_acceptorDoesNotMatchWhenNoFlattenedValueMatches() async throws {
        let unexpected = "not the expected name"
        let output = outputTree(embeddedName: unexpected)
        let subject = try WaitersClient.flattenMatcherWaiterConfig().acceptors[0]
        let match = subject.evaluate(input: anInput, result: .success(output))
        XCTAssertNil(match)
    }

    // JMESPath expression: length(children[].grandchildren[]) == `6`
    // JMESPath comparator: booleanEquals
    // JMESPath expected value: true

    func test_flattenLength_acceptorMatchesWhenFlattenedValueMatchesCount() async throws {
        let unexpected = "not the expected name"
        let output = outputTree(embeddedName: unexpected)
        let subject = try WaitersClient.flattenLengthMatcherWaiterConfig().acceptors[0]
        let match = subject.evaluate(input: anInput, result: .success(output))
        XCTAssertEqual(match, .success(.success(output)))
    }

    // MARK: - Length - Flatten - Filter

    // JMESPath expression: length((children[].grandchildren[])[?number > `4`]) == `3`
    // JMESPath comparator: booleanEquals
    // JMESPath expected value: true

    func test_lengthFlattenFilter_acceptorMatchesWhenFilterMatches() async throws {
        let output = outputTree(appendBonusKid: true)
        let subject = try WaitersClient.lengthFlattenFilterMatcherWaiterConfig().acceptors[0]
        let match = subject.evaluate(input: anInput, result: .success(output))
        XCTAssertEqual(match, .success(.success(output)))
    }

    func test_lengthFlattenFilter_acceptorDoesNotMatchWhenFilterDoesNotMatch() async throws {
        let output = outputTree()
        let subject = try WaitersClient.lengthFlattenFilterMatcherWaiterConfig().acceptors[0]
        let match = subject.evaluate(input: anInput, result: .success(output))
        XCTAssertNil(match)
    }

    // MARK: - Flatten - Filter

    // JMESPath expression: length(children[?length(grandchildren) == `3`]) == `1`
    // JMESPath comparator: booleanEquals
    // JMESPath expected value: true

    func test_flattenFilter_acceptorMatchesWhenFlattenedValueMatchesCount() async throws {
        let output = outputTree(appendBonusKid: true)
        let subject = try WaitersClient.flattenFilterMatcherWaiterConfig().acceptors[0]
        let match = subject.evaluate(input: anInput, result: .success(output))
        XCTAssertEqual(match, .success(.success(output)))
    }

    func test_flattenFilter_acceptorDoesNotMatchWhenFlattenedValueDoesntMatchCount() async throws {
        let output = outputTree()
        let subject = try WaitersClient.flattenFilterMatcherWaiterConfig().acceptors[0]
        let match = subject.evaluate(input: anInput, result: .success(output))
        XCTAssertNil(match)
    }

    // MARK: - Projection

    // JMESPath expression: "dataMap.*"
    // JMESPath comparator: "allStringEquals"
    // JMESPath expected value: "abc"

    func test_projection_acceptorMatchesWhenProjectedValuesMatchExpectation() async throws {
        let output = GetWidgetOutput(dataMap: ["x": "abc", "y": "abc", "z": "abc"])
        let subject = try WaitersClient.projectionMatcherWaiterConfig().acceptors[0]
        let match = subject.evaluate(input: anInput, result: .success(output))
        XCTAssertEqual(match, .success(.success(output)))
    }

    func test_projection_acceptorDoesNotMatchWhenProjectedValuesDontMatchExpectation() async throws {
        let output = GetWidgetOutput(dataMap: ["x": "abc", "y": "abc", "z": "def"])
        let subject = try WaitersClient.projectionMatcherWaiterConfig().acceptors[0]
        let match = subject.evaluate(input: anInput, result: .success(output))
        XCTAssertNil(match)
    }

    // MARK: - Contains non-literal, optional search param

    // JMESPath expression: "contains(dataMap.*, stringProperty)"
    // JMESPath comparator: "booleanEquals"
    // JMESPath expected value: "true"

    func test_containsNonLiteral_acceptorMatchesWhenStringPropertyIsFound() async throws {
        let output = GetWidgetOutput(dataMap: ["a": "abc", "b": "xyz"], stringProperty: "xyz")
        let subject = try WaitersClient.containsFieldMatcherWaiterConfig().acceptors[0]
        let match = subject.evaluate(input: anInput, result: .success(output))
        XCTAssertEqual(match, .success(.success(output)))
    }

    func test_containsNonLiteral_acceptorDoesNotMatchWhenStringPropertyIsNotFound() async throws {
        let output = GetWidgetOutput(dataMap: ["a": "abc", "b": "xyz"], stringProperty: "def")
        let subject = try WaitersClient.containsFieldMatcherWaiterConfig().acceptors[0]
        let match = subject.evaluate(input: anInput, result: .success(output))
        XCTAssertNil(match)
    }

    // MARK: - Contains AND expression and number equality/inequality comparison

    // JMESPath expression: "length(dataMap) == `3` && length(stringArrayProperty) != `3`"
    // JMESPath comparator: "booleanEquals"
    // JMESPath expected value: "true"

    func test_andInequality_acceptorMatchesWhenCountsAreThreeAndNotThree() async throws {
        let output = GetWidgetOutput(dataMap: ["a": "a", "b": "b", "c": "c"], stringArrayProperty: ["a", "b"])
        let subject = try WaitersClient.andInequalityMatcherWaiterConfig().acceptors[0]
        let match = subject.evaluate(input: anInput, result: .success(output))
        XCTAssertEqual(match, .success(.success(output)))
    }

    func test_andInequality_acceptorDoesNotMatchWhenCountsAreNotThreeAndThree() async throws {
        let output = GetWidgetOutput(dataMap: ["a": "a", "b": "b"], stringArrayProperty: ["a", "b", "c"])
        let subject = try WaitersClient.andInequalityMatcherWaiterConfig().acceptors[0]
        let match = subject.evaluate(input: anInput, result: .success(output))
        XCTAssertNil(match)
    }

    // MARK: - Helper methods

    private func outputTree(globalName: String? = nil, embeddedName: String? = "c", appendBonusKid: Bool = false) -> GetWidgetOutput {
        var grandchildren2: [WaitersClientTypes.Grandchild] = [
            .init(name: embeddedName ?? globalName, number: 1),
            .init(name: globalName ?? "d", number: 2)
        ]
        if appendBonusKid { grandchildren2.append(.init(name: "bonus kid", number: 7))}
        return GetWidgetOutput(children: [
            .init(grandchildren: [
                .init(name: globalName ?? "a", number: 3),
                .init(name: globalName ?? "b", number: 4)
            ]),
            .init(grandchildren: grandchildren2),
            .init(grandchildren: [
                .init(name: globalName ?? "e", number: 5),
                .init(name: globalName ?? "f", number: 6)
            ])
        ])
    }
}

