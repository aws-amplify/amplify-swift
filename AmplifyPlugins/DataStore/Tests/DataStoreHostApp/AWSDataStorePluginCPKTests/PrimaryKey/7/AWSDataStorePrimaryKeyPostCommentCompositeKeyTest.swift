//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation
import XCTest
import Amplify

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
extension AWSDataStorePrimaryKeyPostCommentCompositeKeyTest {
    struct CompositeKeyWithAssociations: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: PostWithCompositeKey.self)
            ModelRegistry.register(modelType: CommentWithCompositeKey.self)
        }
    }
}
