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

/*
 # iOS.7. A Has-Many/Belongs-To relationship, each with a composite key
 # Post with `id` and `title`, Comment with `id` and `content`

 type PostWithCompositeKey @model {
     id: ID! @primaryKey(sortKeyFields: ["title"])
     title: String!
     comments: [CommentWithCompositeKey] @hasMany
 }

 type CommentWithCompositeKey @model {
     id: ID! @primaryKey(sortKeyFields: ["content"])
     content: String!
     post: PostWithCompositeKey @belongsTo
 }

 */
final class AWSDataStorePrimaryKeyPostCommentCompositeKeyTest: AWSDataStorePrimaryKeyBaseTest {

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
extension AWSDataStorePrimaryKeyPostCommentCompositeKeyTest {
    struct CompositeKeyWithAssociations: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: PostWithCompositeKey.self)
            ModelRegistry.register(modelType: CommentWithCompositeKey.self)
        }
    }
}
