//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSDataStorePlugin

class DataStoreScalarTests: SyncEngineIntegrationTestBase {

    struct TestModelRegistration: AmplifyModelRegistration {
        func registerModels(registry: ModelRegistry.Type) {
            registry.register(modelType: ScalarContainer.self)
            registry.register(modelType: ListIntContainer.self)
            registry.register(modelType: ListStringContainer.self)
            registry.register(modelType: EnumTestModel.self)
            registry.register(modelType: NestedTypeTestModel.self)
        }

        let version: String = "1"
    }

    func testScalarContainer() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
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
        let savedModel = try await Amplify.DataStore.save(container)
        XCTAssertEqual(savedModel, container)
        let updatedModel = try await Amplify.DataStore.save(updatedContainer)
        XCTAssertEqual(updatedModel, updatedContainer)
        let queriedModel = try await Amplify.DataStore.query(ScalarContainer.self, byId: container.id)
        XCTAssertEqual(queriedModel, updatedContainer)
        try await Amplify.DataStore.delete(updatedContainer)
        let emptyModel = try await Amplify.DataStore.query(ScalarContainer.self, byId: container.id)
        XCTAssertNil(emptyModel)
    }

    func testListIntContainer() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
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
        let savedModel = try await Amplify.DataStore.save(container)
        XCTAssertEqual(savedModel, container)
        let updatedModel = try await Amplify.DataStore.save(updatedContainer)
        XCTAssertEqual(updatedModel, updatedContainer)
        let queriedModel = try await Amplify.DataStore.query(ListIntContainer.self, byId: container.id)
        XCTAssertEqual(queriedModel, updatedContainer)
        try await Amplify.DataStore.delete(updatedContainer)
        let emptyModel = try await Amplify.DataStore.query(ListIntContainer.self, byId: container.id)
        XCTAssertNil(emptyModel)
    }

    func testListStringContainer() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
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
        let savedModel = try await Amplify.DataStore.save(container)
        XCTAssertEqual(savedModel, container)
        let updatedModel = try await Amplify.DataStore.save(updatedContainer)
        XCTAssertEqual(updatedModel, updatedContainer)
        let queriedModel = try await Amplify.DataStore.query(ListStringContainer.self, byId: container.id)
        XCTAssertEqual(queriedModel, updatedContainer)

        try await Amplify.DataStore.delete(updatedContainer)
        let emptyModel = try await Amplify.DataStore.query(ListStringContainer.self, byId: container.id)
        XCTAssertNil(emptyModel)
    }

    func testListContainerWithNil() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
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
        let savedModel = try await Amplify.DataStore.save(container)
        XCTAssertEqual(savedModel, container)
        let updatedModel = try await Amplify.DataStore.save(updatedContainer)
        XCTAssertEqual(updatedModel, updatedContainer)
        let queriedModel = try await Amplify.DataStore.query(ListStringContainer.self, byId: container.id)
        XCTAssertEqual(queriedModel, updatedContainer)
        try await Amplify.DataStore.delete(updatedContainer)
        let emptyModel = try await Amplify.DataStore.query(ListStringContainer.self, byId: container.id)
        XCTAssertNil(emptyModel)
    }

    func testEnumTestModel() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
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
        let savedModel = try await Amplify.DataStore.save(container)
        XCTAssertEqual(savedModel, container)
        let updatedModel = try await Amplify.DataStore.save(updatedContainer)
        XCTAssertEqual(updatedModel, updatedContainer)
        let queriedModel = try await Amplify.DataStore.query(EnumTestModel.self, byId: container.id)
        XCTAssertEqual(queriedModel, updatedContainer)
        try await Amplify.DataStore.delete(updatedContainer)
        let emptyModel = try await Amplify.DataStore.query(EnumTestModel.self, byId: container.id)
        XCTAssertNil(emptyModel)
    }

    func testNestedEnumTestModel() async throws {
        await setUp(withModels: TestModelRegistration())
        try await startAmplifyAndWaitForSync()
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

        let savedModel = try await Amplify.DataStore.save(container)
        XCTAssertEqual(savedModel, container)
        let updatedModel = try await Amplify.DataStore.save(updatedContainer)
        XCTAssertEqual(updatedModel, updatedContainer)

        let queriedModel = try await Amplify.DataStore.query(NestedTypeTestModel.self, byId: container.id)
        XCTAssertEqual(queriedModel, updatedContainer)

        try await Amplify.DataStore.delete(updatedContainer)
        let emptyModel = try await Amplify.DataStore.query(NestedTypeTestModel.self, byId: container.id)
        XCTAssertNil(emptyModel)
    }
}
