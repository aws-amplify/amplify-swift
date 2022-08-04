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

    func testModelWithCompositePrimaryKeyAndAssociations() {
        setup(withModels: CompositeKeyWithAssociations())

        let expectations = makeExpectations()

        assertDataStoreReady(expectations)

        // Query
        assertQuerySuccess(modelType: PostWithCompositeKey.self,
                           expectations) { error in
            XCTFail("Error query \(error)")
        }

        let parent = PostWithCompositeKey(title: "Post22")
        let child = CommentWithCompositeKey(content: "Comment", post: parent)

        // Mutations
        assertMutationsParentChild(parent: parent, child: child, expectations) { error in
            XCTFail("Error mutation \(error)")
        }

        // Child should not exists as we've deleted the parent
        assertModelDeleted(modelType: CommentWithCompositeKey.self,
                           identifier: .identifier(id: child.id, content: child.content)) { error in
            XCTFail("Error deleting child \(error)")
        }
    }

    /// - Given: a set models with a belongs-to association and composite primary keys
    /// - When:
    ///     - the parent model is saved
    ///     - a child model is saved
    ///     - query the children by the parent identifier
    /// - Then:
    ///     - query returns the saved child model
    func testModelWithCompositePrimaryKeyAndQueryPredicate() {
        setup(withModels: CompositeKeyWithAssociations())

        let expectations = makeExpectations()

        // use the same expectation for both post and comments
        expectations.mutationSave.expectedFulfillmentCount = 2
        expectations.mutationSaveProcessed.fulfill()

        // we're not testing deletes
        expectations.mutationDelete.fulfill()
        expectations.mutationDeleteProcessed.fulfill()

        assertDataStoreReady(expectations)
        let post = PostWithCompositeKey(title: "title")
        let comment = CommentWithCompositeKey(content: "content", post: post)

        Amplify.DataStore.save(post) {
            if case let .failure(error) = $0 {
                XCTFail("Failed saving post with error \(error.errorDescription)")
            }
            expectations.mutationSave.fulfill()
        }

        Amplify.DataStore.save(comment) {
            if case let .failure(error) = $0 {
                XCTFail("Failed saving post with error \(error.errorDescription)")
            }
            expectations.mutationSave.fulfill()
        }

        let predicate = CommentWithCompositeKey.keys.post == post.identifier
        Amplify.DataStore.query(CommentWithCompositeKey.self, where: predicate) {
            switch $0 {
            case .failure(let error):
                XCTFail("Failed query comments with error \(error.errorDescription)")
            case .success(let savedComments):
                XCTAssertNotNil(savedComments)
                XCTAssertEqual(savedComments.count, 1)
                XCTAssertEqual(savedComments[0].id, comment.id)
                XCTAssertEqual(savedComments[0].content, comment.content)
                expectations.query.fulfill()
            }
        }

        wait(for: [expectations.query,
                   expectations.mutationSave,
                   expectations.mutationSaveProcessed,
                   expectations.mutationDelete,
                   expectations.mutationDeleteProcessed], timeout: 60)
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
