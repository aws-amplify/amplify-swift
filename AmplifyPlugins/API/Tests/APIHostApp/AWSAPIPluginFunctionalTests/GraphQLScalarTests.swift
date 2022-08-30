//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSAPIPlugin
@testable import Amplify
@testable import APIHostApp

class GraphQLScalarTests: GraphQLTestBase {

    override func setUp() {
        do {
            Amplify.Logging.logLevel = .verbose
            try Amplify.add(plugin: AWSAPIPlugin())

            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(
                forResource: GraphQLModelBasedTests.amplifyConfiguration)
            try Amplify.configure(amplifyConfig)

            ModelRegistry.register(modelType: ScalarContainer.self)
            ModelRegistry.register(modelType: ListIntContainer.self)
            ModelRegistry.register(modelType: ListStringContainer.self)
            ModelRegistry.register(modelType: EnumTestModel.self)
            ModelRegistry.register(modelType: NestedTypeTestModel.self)

        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func tearDown() async throws {
        await Amplify.reset()
    }

    func testScalarContainer() async throws {
        let container = ScalarContainer(myString: "myString",
                                        myInt: 1,
                                        myDouble: 1.0,
                                        myBool: true,
                                        myDate: .now(),
                                        myTime: .now(),
                                        myDateTime: .now(),
                                        myTimeStamp: 123,
                                        myEmail: "local-part@domain-part",
                                        myJSON: "{}",
                                        myPhone: "2342355678",
                                        myURL: "https://www.amazon.com/dp/B000NZW3KC/",
                                        myIPAddress: "123.12.34.56")
        let updatedContainer = ScalarContainer(id: container.id)

        let createdModel = try await mutateModel(request: .create(container))
        XCTAssertEqual(createdModel, container)

        let updatedModel = try await mutateModel(request: .update(updatedContainer))
        XCTAssertEqual(updatedModel, updatedContainer)

        guard let queriedModel =
                try await queryModel(request: .get(ScalarContainer.self, byId: container.id)) else {
            XCTFail("Failed to query model")
            return
        }
        XCTAssertEqual(queriedModel, updatedContainer)

        let deletedModel = try await mutateModel(request: .delete(updatedContainer))
        XCTAssertEqual(deletedModel, updatedContainer)

        let emptyModel = try await queryModel(request: .get(ScalarContainer.self, byId: container.id))
        XCTAssertNil(emptyModel)
    }

    func testListIntContainer() async throws {
        let container = ListIntContainer(
            test: 1,
            nullableInt: 1,
            intList: [],
            intNullableList: [],
            nullableIntList: [],
            nullableIntNullableList: nil)

        let updatedContainer = ListIntContainer(id: container.id,
                                                test: 2,
                                                nullableInt: nil,
                                                intList: [1, 2, 3],
                                                intNullableList: [1, 2, 3],
                                                nullableIntList: [1, 2, 3],
                                                nullableIntNullableList: [1, 2, 3])

        let createdModel = try await mutateModel(request: .create(container))
        XCTAssertEqual(createdModel, container)

        let updatedModel = try await mutateModel(request: .update(updatedContainer))
        XCTAssertEqual(updatedModel, updatedContainer)

        guard let queriedModel = try await queryModel(request: .get(ListIntContainer.self, byId: container.id)) else {
            XCTFail("Failed to query model")
            return
        }
        XCTAssertEqual(queriedModel, updatedContainer)

        let deletedModel = try await mutateModel(request: .delete(updatedContainer))
        XCTAssertEqual(deletedModel, updatedContainer)

        let emptyModel = try await queryModel(request: .get(ListIntContainer.self, byId: container.id))
        XCTAssertNil(emptyModel)
    }

    func testListStringContainer() async throws {
        let container = ListStringContainer(
            test: "test",
            nullableString: nil,
            stringList: ["value1"],
            stringNullableList: [],
            nullableStringList: [],
            nullableStringNullableList: nil)

        let updatedContainer = ListStringContainer(id: container.id,
                                                   test: "test",
                                                   nullableString: "test",
                                                   stringList: ["value1"],
                                                   stringNullableList: ["value1"],
                                                   nullableStringList: ["value1"],
                                                   nullableStringNullableList: ["value1"])
        let createdModel = try await mutateModel(request: .create(container))
        XCTAssertEqual(createdModel, container)

        let updatedModel = try await mutateModel(request: .update(updatedContainer))
        XCTAssertEqual(updatedModel, updatedContainer)

        guard let queriedModel = try await queryModel(request: .get(ListStringContainer.self,
                                                                    byId: container.id)) else {
            XCTFail("Failed to query model")
            return
        }
        XCTAssertEqual(queriedModel, updatedContainer)

        let deletedModel = try await mutateModel(request: .delete(updatedContainer))
        XCTAssertEqual(deletedModel, updatedContainer)

        let emptyModel = try await queryModel(request: .get(ListStringContainer.self, byId: container.id))
        XCTAssertNil(emptyModel)
    }

    func testListContainerWithNil() async throws {
        let container = ListStringContainer(
            test: "test",
            nullableString: nil,
            stringList: ["value1"],
            stringNullableList: nil,
            nullableStringList: [nil],
            nullableStringNullableList: nil)

        let updatedContainer = ListStringContainer(id: container.id,
                                                   test: "test",
                                                   nullableString: "test",
                                                   stringList: ["value1"],
                                                   stringNullableList: ["value1"],
                                                   nullableStringList: ["value1"],
                                                   nullableStringNullableList: ["value1"])
        let createdModel = try await mutateModel(request: .create(container))
        XCTAssertEqual(createdModel, container)

        let updatedModel = try await mutateModel(request: .update(updatedContainer))
        XCTAssertEqual(updatedModel, updatedContainer)

        guard let queriedModel = try await queryModel(request: .get(ListStringContainer.self,
                                                                    byId: container.id)) else {
            XCTFail("Failed to query model")
            return
        }
        XCTAssertEqual(queriedModel, updatedContainer)

        let deletedModel = try await mutateModel(request: .delete(updatedContainer))
        XCTAssertEqual(deletedModel, updatedContainer)

        let emptyModel = try await queryModel(request: .get(ListStringContainer.self, byId: container.id))
        XCTAssertNil(emptyModel)
    }

    func testEnumTestModel() async throws {
        let container = EnumTestModel(enumVal: .valueOne,
                                      nullableEnumVal: .valueTwo,
                                      enumList: [.valueOne],
                                      enumNullableList: [.valueTwo],
                                      nullableEnumList: [.valueOne, .valueTwo],
                                      nullableEnumNullableList: [.valueTwo, .valueOne])
        let updatedContainer = EnumTestModel(id: container.id,
                                             enumVal: .valueTwo,
                                             nullableEnumVal: nil,
                                             enumList: [.valueTwo],
                                             enumNullableList: [.valueTwo, .valueOne],
                                             nullableEnumList: [.valueTwo, .valueOne],
                                             nullableEnumNullableList: [.valueOne, .valueTwo])
        let createdModel = try await mutateModel(request: .create(container))
        XCTAssertEqual(createdModel, container)

        let updatedModel = try await mutateModel(request: .update(updatedContainer))
        XCTAssertEqual(updatedModel, updatedContainer)

        guard let queriedModel = try await queryModel(request: .get(EnumTestModel.self, byId: container.id)) else {
            XCTFail("Failed to query model")
            return
        }
        XCTAssertEqual(queriedModel, updatedContainer)

        let deletedModel = try await mutateModel(request: .delete(updatedContainer))
        XCTAssertEqual(deletedModel, updatedContainer)

        let emptyModel = try await queryModel(request: .get(EnumTestModel.self, byId: container.id))
        XCTAssertNil(emptyModel)
    }

    func testNestedEnumTestModel() async throws {
        let container = NestedTypeTestModel(nestedVal: .init(valueOne: 1),
                                            nullableNestedVal: .init(),
                                            nestedList: [.init(valueTwo: "value2")],
                                            nestedNullableList: [.init()],
                                            nullableNestedList: [.init(valueOne: 1, valueTwo: "value2")],
                                            nullableNestedNullableList: [.init(valueOne: 1, valueTwo: "value2")])

        let updatedContainer = NestedTypeTestModel(id: container.id,
                                                   nestedVal: .init(valueOne: 1),
                                                   nullableNestedVal: .init(),
                                                   nestedList: [.init(valueTwo: "updatedValue"), .init(valueOne: 1)],
                                                   nestedNullableList: [.init(valueOne: 1, valueTwo: "value2")],
                                                   nullableNestedList: [],
                                                   nullableNestedNullableList: nil)

        let createdModel = try await mutateModel(request: .create(container))
        XCTAssertEqual(createdModel, container)

        let updatedModel = try await mutateModel(request: .update(updatedContainer))
        XCTAssertEqual(updatedModel, updatedContainer)

        guard let queriedModel = try await queryModel(request: .get(NestedTypeTestModel.self,
                                                                    byId: container.id)) else {
            XCTFail("Failed to query model")
            return
        }
        XCTAssertEqual(queriedModel, updatedContainer)

        let deletedModel = try await mutateModel(request: .delete(updatedContainer))
        XCTAssertEqual(deletedModel, updatedContainer)

        let emptyModel = try await queryModel(request: .get(NestedTypeTestModel.self, byId: container.id))
        XCTAssertNil(emptyModel)
    }
}

extension ScalarContainer: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return (lhs.id == rhs.id
                    && lhs.myInt == rhs.myInt
                    && lhs.myDouble == rhs.myDouble
                    && lhs.myBool == rhs.myBool
                    && lhs.myDate == rhs.myDate
                    && lhs.myTime == rhs.myTime
                    && lhs.myDateTime == rhs.myDateTime
                    && lhs.myTimeStamp == rhs.myTimeStamp
                    && lhs.myEmail == rhs.myEmail
                    && lhs.myJSON == rhs.myJSON
                    && lhs.myPhone == rhs.myPhone
                    && lhs.myURL == rhs.myURL
                    && lhs.myIPAddress == rhs.myIPAddress)
    }
}

extension ListIntContainer: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return (lhs.id == rhs.id
                    && lhs.test == rhs.test
                    && lhs.nullableInt == rhs.nullableInt
                    && lhs.intList == rhs.intList
                    && lhs.intNullableList == rhs.intNullableList
                    && lhs.nullableIntList == rhs.nullableIntList
                    && lhs.nullableIntNullableList == rhs.nullableIntNullableList)
    }
}

extension ListStringContainer: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return (lhs.id == rhs.id
                    && lhs.test == rhs.test
                    && lhs.nullableString == rhs.nullableString
                    && lhs.stringList == rhs.stringList
                    && lhs.stringNullableList == rhs.stringNullableList
                    && lhs.nullableStringList == rhs.nullableStringList
                    && lhs.nullableStringNullableList == rhs.nullableStringNullableList)
    }
}

extension EnumTestModel: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return (lhs.id == rhs.id
                    && lhs.enumVal == rhs.enumVal
                    && lhs.nullableEnumVal == rhs.nullableEnumVal
                    && lhs.enumList == rhs.enumList
                    && lhs.enumNullableList == rhs.enumNullableList
                    && lhs.nullableEnumList == rhs.nullableEnumList
                    && lhs.nullableEnumNullableList == rhs.nullableEnumNullableList)
    }
}
extension NestedTypeTestModel: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return (lhs.id == rhs.id
                    && lhs.nestedVal == rhs.nestedVal
                    && lhs.nullableNestedVal == rhs.nullableNestedVal
                    && lhs.nestedList == rhs.nestedList
                    && lhs.nestedNullableList == rhs.nestedNullableList
                    && lhs.nullableNestedList == rhs.nullableNestedList
                    && lhs.nullableNestedNullableList == rhs.nullableNestedNullableList)
    }
}

extension Nested: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        return (lhs.valueOne == rhs.valueOne
                    && lhs.valueTwo == rhs.valueTwo)
    }
}
