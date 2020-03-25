//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
import XCTest

class AnyQueryPredicateTests: XCTestCase {

    override func setUp() {
        ModelRegistry.register(modelType: AnyModelTester.self)
    }

    func testAnyQueryPredicateToJsonAndBack() throws {
        let anyModelTester = AnyModelTester.keys
        let predicate = (anyModelTester.intProperty == 1 || anyModelTester.intProperty == 2)
            && anyModelTester.stringProperty.contains("some string")
            || anyModelTester.stringProperty.beginsWith("some string")
        let anyQueryPredicate = AnyQueryPredicate(predicate)

        let json = try anyQueryPredicate.toJSON()
        XCTAssertNotNil(json)
        let actualPredicate = try AnyQueryPredicate.from(json: json).base
        XCTAssertNotNil(actualPredicate)

        guard let actualQueryPredicate = actualPredicate as? QueryPredicateGroup else {
            XCTFail("Could not get QueryPredicateGroup")
            return
        }
        XCTAssertEqual(predicate, actualQueryPredicate)
    }
}
