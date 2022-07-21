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

    func testScalarContainer() throws {
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

        guard case .success(let createdModel) = mutateModel(request: .create(container)) else {
            XCTFail("Failed to create model")
            return
        }
        XCTAssertEqual(createdModel, container)

        guard case .success(let updatedModel) = mutateModel(request: .update(updatedContainer)) else {
            XCTFail("Failed to update model")
            return
        }
        XCTAssertEqual(updatedModel, updatedContainer)

        guard case .success(let queriedModel) =
                queryModel(request: .get(ScalarContainer.self, byId: container.id)) else {
            XCTFail("Failed to query model")
            return
        }
        XCTAssertEqual(queriedModel, updatedContainer)

        guard case .success(let deletedModel) = mutateModel(request: .delete(updatedContainer)) else {
            XCTFail("Failed to delete model")
            return
        }
        XCTAssertEqual(deletedModel, updatedContainer)

        guard case .success(let emptyModel) =
                queryModel(request: .get(ScalarContainer.self, byId: container.id)) else {
            XCTFail("Failed to query deleted model")
            return
        }
        XCTAssertNil(emptyModel)
    }

    func testListIntContainer() throws {
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

        guard case .success(let createdModel) = mutateModel(request: .create(container)) else {
            XCTFail("Failed to create model")
            return
        }
        XCTAssertEqual(createdModel, container)

        guard case .success(let updatedModel) = mutateModel(request: .update(updatedContainer)) else {
            XCTFail("Failed to update model")
            return
        }
        XCTAssertEqual(updatedModel, updatedContainer)

        guard case .success(let queriedModel) =
                queryModel(request: .get(ListIntContainer.self, byId: container.id)) else {
            XCTFail("Failed to query model")
            return
        }
        XCTAssertEqual(queriedModel, updatedContainer)

        guard case .success(let deletedModel) = mutateModel(request: .delete(updatedContainer)) else {
            XCTFail("Failed to delete model")
            return
        }
        XCTAssertEqual(deletedModel, updatedContainer)

        guard case .success(let emptyModel) =
                queryModel(request: .get(ListIntContainer.self, byId: container.id)) else {
            XCTFail("Failed to query deleted model")
            return
        }
        XCTAssertNil(emptyModel)
    }

    func testListStringContainer() throws {
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
        guard case .success(let createdModel) = mutateModel(request: .create(container)) else {
            XCTFail("Failed to create model")
            return
        }
        XCTAssertEqual(createdModel, container)

        guard case .success(let updatedModel) = mutateModel(request: .update(updatedContainer)) else {
            XCTFail("Failed to update model")
            return
        }
        XCTAssertEqual(updatedModel, updatedContainer)

        guard case .success(let queriedModel) =
                queryModel(request: .get(ListStringContainer.self, byId: container.id)) else {
            XCTFail("Failed to query model")
            return
        }
        XCTAssertEqual(queriedModel, updatedContainer)

        guard case .success(let deletedModel) = mutateModel(request: .delete(updatedContainer)) else {
            XCTFail("Failed to delete model")
            return
        }
        XCTAssertEqual(deletedModel, updatedContainer)

        guard case .success(let emptyModel) =
                queryModel(request: .get(ListStringContainer.self, byId: container.id)) else {
            XCTFail("Failed to query deleted model")
            return
        }
        XCTAssertNil(emptyModel)
    }

    func testListContainerWithNil() {
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
        guard case .success(let createdModel) = mutateModel(request: .create(container)) else {
            XCTFail("Failed to create model")
            return
        }
        XCTAssertEqual(createdModel, container)

        guard case .success(let updatedModel) = mutateModel(request: .update(updatedContainer)) else {
            XCTFail("Failed to update model")
            return
        }
        XCTAssertEqual(updatedModel, updatedContainer)

        guard case .success(let queriedModel) =
                queryModel(request: .get(ListStringContainer.self, byId: container.id)) else {
            XCTFail("Failed to query model")
            return
        }
        XCTAssertEqual(queriedModel, updatedContainer)

        guard case .success(let deletedModel) = mutateModel(request: .delete(updatedContainer)) else {
            XCTFail("Failed to delete model")
            return
        }
        XCTAssertEqual(deletedModel, updatedContainer)

        guard case .success(let emptyModel) =
                queryModel(request: .get(ListStringContainer.self, byId: container.id)) else {
            XCTFail("Failed to query deleted model")
            return
        }
        XCTAssertNil(emptyModel)
    }

    func testEnumTestModel() throws {
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
        guard case .success(let createdModel) = mutateModel(request: .create(container)) else {
            XCTFail("Failed to create model")
            return
        }
        XCTAssertEqual(createdModel, container)

        guard case .success(let updatedModel) = mutateModel(request: .update(updatedContainer)) else {
            XCTFail("Failed to update model")
            return
        }
        XCTAssertEqual(updatedModel, updatedContainer)

        guard case .success(let queriedModel) =
                queryModel(request: .get(EnumTestModel.self, byId: container.id)) else {
            XCTFail("Failed to query model")
            return
        }
        XCTAssertEqual(queriedModel, updatedContainer)

        guard case .success(let deletedModel) = mutateModel(request: .delete(updatedContainer)) else {
            XCTFail("Failed to delete model")
            return
        }
        XCTAssertEqual(deletedModel, updatedContainer)

        guard case .success(let emptyModel) =
                queryModel(request: .get(EnumTestModel.self, byId: container.id)) else {
            XCTFail("Failed to query deleted model")
            return
        }
        XCTAssertNil(emptyModel)
    }

    func testNestedEnumTestModel() throws {
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

        guard case .success(let createdModel) = mutateModel(request: .create(container)) else {
            XCTFail("Failed to create model")
            return
        }
        XCTAssertEqual(createdModel, container)

        guard case .success(let updatedModel) = mutateModel(request: .update(updatedContainer)) else {
            XCTFail("Failed to update model")
            return
        }
        XCTAssertEqual(updatedModel, updatedContainer)

        guard case .success(let queriedModel) =
                queryModel(request: .get(NestedTypeTestModel.self, byId: container.id)) else {
            XCTFail("Failed to query model")
            return
        }
        XCTAssertEqual(queriedModel, updatedContainer)

        guard case .success(let deletedModel) = mutateModel(request: .delete(updatedContainer)) else {
            XCTFail("Failed to delete model")
            return
        }
        XCTAssertEqual(deletedModel, updatedContainer)

        guard case .success(let emptyModel) =
                queryModel(request: .get(NestedTypeTestModel.self, byId: container.id)) else {
            XCTFail("Failed to query deleted model")
            return
        }
        XCTAssertNil(emptyModel)
    }
}
