//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import Amplify

class AWSDataStorePrimaryKeyIntegrationTests: AWSDataStorePrimaryKeyBaseTest {

    func testModelWithImplicitDefaultPrimaryKey() async throws {
        setup(withModels: DefaultImplicitPKModels())
        try await assertDataStoreReady()
        try await assertQuerySuccess(modelType: ModelImplicitDefaultPk.self)
        let model = ModelImplicitDefaultPk(name: "model-name")
        try await assertMutations(model: model)
    }

    func testModelWithExplicitDefaultPrimaryKey() async throws {
        setup(withModels: DefaultExplicitPKModels())
        try await assertDataStoreReady()
        try await assertQuerySuccess(modelType: ModelExplicitDefaultPk.self)
        let model = ModelExplicitDefaultPk(name: "model-name")
        try await assertMutations(model: model)
    }

    func testModelWithCustomPrimaryKey() async throws {
        setup(withModels: CustomExplicitPKModels())
        try await assertDataStoreReady()
        try await assertQuerySuccess(modelType: ModelExplicitCustomPk.self)
        let model = ModelExplicitCustomPk(userId: UUID().uuidString, name: "name")
        try await assertMutations(model: model)
    }

    func testModelWithCompositePrimaryKey() async throws {
        setup(withModels: CompositePKModels())
        try await assertDataStoreReady()
        try await assertQuerySuccess(modelType: ModelCompositePk.self)
        let model = ModelCompositePk(dob: Temporal.DateTime.now(), name: "name")
        try await assertMutations(model: model)
    }

    func testModelWithCompositePrimaryKeyWithIntValue() async throws {
        setup(withModels: CompositePKModelsWithInt())
        try await assertDataStoreReady()
        try await assertQuerySuccess(modelType: ModelCompositeIntPk.self)
        let model = ModelCompositeIntPk(id: UUID().uuidString, serial: 1)
        try await assertMutations(model: model)
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
