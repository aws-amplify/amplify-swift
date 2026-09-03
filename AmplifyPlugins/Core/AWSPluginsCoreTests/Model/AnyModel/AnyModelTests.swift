//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import XCTest

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class AnyModelTests: XCTestCase, @unchecked Sendable {

    override func setUp() {
        ModelRegistry.register(modelType: AnyModelTester.self)
    }

    func testModelName() throws {
        let tester = AnyModelTester(stringProperty: "test", intProperty: -123)

        let anyModel = try tester.eraseToAnyModel()

        XCTAssertEqual(anyModel.modelName, tester.modelName)
    }

    func testDecode() throws {
        let tester = AnyModelTester(stringProperty: "test", intProperty: -123)
        let originalAnyModel = try tester.eraseToAnyModel()
        let jsonEncoded = try JSONEncoder().encode(originalAnyModel)

        let decodedAnyModel = try JSONDecoder().decode(AnyModel.self, from: jsonEncoded)

        XCTAssertEqual(originalAnyModel, decodedAnyModel)
    }

    func testId() throws {
        let tester = AnyModelTester(stringProperty: "test", intProperty: -123)

        let anyModel = try tester.eraseToAnyModel()

        XCTAssertEqual(anyModel.id, tester.id)
    }

    func testIntSubscript() throws {
        let tester = AnyModelTester(stringProperty: "test", intProperty: -123)

        let anyModel = try tester.eraseToAnyModel()

        guard let intProperty = anyModel["intProperty"] as? Int else {
            XCTFail("Couldn't get intProperty as Int")
            return
        }
        XCTAssertEqual(intProperty, tester.intProperty)
    }

    func testStringSubscript() throws {
        let tester = AnyModelTester(stringProperty: "test", intProperty: -123)

        let anyModel = try tester.eraseToAnyModel()

        guard let stringProperty = anyModel["stringProperty"] as? String else {
            XCTFail("Couldn't get stringProperty as String")
            return
        }
        XCTAssertEqual(stringProperty, tester.stringProperty)
    }

    func testSchema() throws {
        let tester = AnyModelTester(stringProperty: "test", intProperty: -123)

        let anyModel = try tester.eraseToAnyModel()

        XCTAssertEqual(anyModel.schema.name, tester.schema.name)
    }
}
