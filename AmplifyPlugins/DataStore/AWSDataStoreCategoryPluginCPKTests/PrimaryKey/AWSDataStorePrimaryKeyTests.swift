//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import Amplify
import AmplifyTestCommon

class AWSDataStorePrimaryKeyIntegrationTests: AWSDataStorePrimaryKeyBaseTest {

    func testModelWithImplicitDefaultPrimaryKey() {
        setup(withModels: DefaultImplicitPKModels())

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: ModelImplicitDefaultPk.self,
                           expectations) { error in
            XCTFail("Error query \(error)")
        }

        let model = ModelImplicitDefaultPk(name: "model-name")

        // Mutations
        assertMutations(model: model, expectations) { error in
            XCTFail("Error mutation \(error)")
        }
    }

    func testModelWithExplicitDefaultPrimaryKey() {
        setup(withModels: DefaultExplicitPKModels())

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: ModelExplicitDefaultPk.self,
                           expectations) { error in
            XCTFail("Error query \(error)")
        }

        let model = ModelExplicitDefaultPk(name: "model-name")

        // Mutations
        assertMutations(model: model, expectations) { error in
            XCTFail("Error mutation \(error)")
        }
    }

    func testModelWithCustomPrimaryKey() {
        setup(withModels: CustomExplicitPKModels())

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: ModelExplicitCustomPk.self,
                           expectations) { error in
            XCTFail("Error query \(error)")
        }

        let model = ModelExplicitCustomPk(userId: UUID().uuidString, name: "name")

        // Mutations
        assertMutations(model: model, expectations) { error in
            XCTFail("Error mutation \(error)")
        }
    }

    func testModelWithCompositePrimaryKey() {
        setup(withModels: CompositePKModels())

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: ModelCompositePk.self,
                           expectations) { error in
            XCTFail("Error query \(error)")
        }

        let model = ModelCompositePk(dob: Temporal.DateTime.now(), name: "name")

        // Mutations
        assertMutations(model: model, expectations) { error in
            XCTFail("Error mutation \(error)")
        }
    }

    func testModelWithCompositePrimaryKeyWithIntValue() {
        setup(withModels: CompositePKModelsWithInt())

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: ModelCompositeIntPk.self,
                           expectations) { error in
            XCTFail("Error query \(error)")
        }

        let model = ModelCompositeIntPk(id: UUID().uuidString, serial: 1)

        // Mutations
        assertMutations(model: model, expectations) { error in
            XCTFail("Error mutation \(error)")
        }
    }
}

extension AWSDataStorePrimaryKeyIntegrationTests {
    struct DefaultImplicitPKModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: ModelImplicitDefaultPk.self)
        }
    }

    struct DefaultExplicitPKModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: ModelExplicitDefaultPk.self)
        }
    }

    struct CustomExplicitPKModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: ModelExplicitCustomPk.self)
        }
    }

    struct CompositePKModels: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: ModelCompositePk.self)
        }
    }

    struct CompositePKModelsWithInt: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: ModelCompositeIntPk.self)
        }
    }
}
