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

    func testModelWithCompositePrimaryKeyAndAssociations() async throws {
        setup(withModels: CompositeKeyWithAssociations())
        try await assertDataStoreReady()
        try await assertQuerySuccess(modelType: PostWithCompositeKey.self)
        let parent = PostWithCompositeKey(title: "Post22")
        let child = CommentWithCompositeKey(content: "Comment", post: parent)
        
        // Mutations
        try await assertMutationsParentChild(parent: parent, child: child)

        // Child should not exists as we've deleted the parent
        try await assertModelDeleted(modelType: CommentWithCompositeKey.self,
                                     identifier: .identifier(id: child.id, content: child.content))
    }

    /// - Given: a set models with a belongs-to association and composite primary keys
    /// - When:
    ///     - the parent model is saved
    ///     - a child model is saved
    ///     - query the children by the parent identifier
    /// - Then:
    ///     - query returns the saved child model
    func testModelWithCompositePrimaryKeyAndQueryPredicate() async throws {
        setup(withModels: CompositeKeyWithAssociations())

        try await assertDataStoreReady()
        
        let post = PostWithCompositeKey(title: "title")
        let comment = CommentWithCompositeKey(content: "content", post: post)
        _ = try await Amplify.DataStore.save(post)
        _ = try await Amplify.DataStore.save(comment)

        let predicate = CommentWithCompositeKey.keys.post == post.identifier
        let savedComments = try await Amplify.DataStore.query(CommentWithCompositeKey.self, where: predicate)
        XCTAssertNotNil(savedComments)
        XCTAssertEqual(savedComments.count, 1)
        XCTAssertEqual(savedComments[0].id, comment.id)
        XCTAssertEqual(savedComments[0].content, comment.content)
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

    struct CompositeKeyWithAssociations: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: PostWithCompositeKey.self)
            ModelRegistry.register(modelType: CommentWithCompositeKey.self)
        }
    }
}
