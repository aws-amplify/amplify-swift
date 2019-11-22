//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import XCTest

class AnyModelTests: XCTestCase {

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

// MARK: - Utilities

struct AnyModelTester: Model {
    let id: Identifier
    let stringProperty: String
    let intProperty: Int

    init(id: Identifier = "test-id", stringProperty: String, intProperty: Int) {
        self.id = id
        self.stringProperty = stringProperty
        self.intProperty = intProperty
    }
}

extension AnyModelTester {
    // MARK: - CodingKeys

    public enum CodingKeys: String, ModelKey {
        case id
        case stringProperty
        case intProperty
    }

    public static let keys = CodingKeys.self

    // MARK: - ModelSchema

    public static let schema = defineSchema { definition in
        let anyModel = AnyModelTester.keys

        definition.fields(
            .id(),
            .field(anyModel.stringProperty, is: .required, ofType: .string),
            .field(anyModel.intProperty, is: .required, ofType: .int)
        )
    }
}

extension AnyModelTester: Equatable { }

extension AnyModel: Equatable {
    public static func == (lhs: AnyModel, rhs: AnyModel) -> Bool {
        //swiftlint:disable force_try
        let lhsInstance = try! lhs.instance.toJSON()
        let rhsInstance = try! rhs.instance.toJSON()
        //swiftlint:enable force_try

        return lhs.id == rhs.id
            && lhs.modelName == rhs.modelName
            && lhsInstance == rhsInstance
    }
}
