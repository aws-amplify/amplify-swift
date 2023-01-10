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
 ## iOS 10. bi-directional has-many PostComment4V2

 type Post4V2 @model @auth(rules: [{allow: public}]) {
   id: ID!
   title: String!
   comments: [Comment4V2] @hasMany(indexName: "byPost4", fields: ["id"])
 }

 type Comment4V2 @model @auth(rules: [{allow: public}]) {
   id: ID!
   postID: ID! @index(name: "byPost4", sortKeyFields: ["content"])
   content: String!
   post: Post4V2 @belongsTo(fields: ["postID"])
 }

 */
final class AWSDataStorePrimaryKeyPostComment4V2Test: AWSDataStorePrimaryKeyBaseTest {

    /// Save Post4V2 and Comment4V2 and ensure they are synced successfully.
    /// This test is from the issue https://github.com/aws-amplify/amplify-swift/issues/2644
    /// The issue appears when using Amplify CLI v10.5.0 which defaults to CPK enabled for new projects.
    /// The swift models generated for this schema doesn't leverage CPK use case, however we are
    /// adding it here to ensure the CPK feature is backwards compatible for models with default identifiers.
    ///
    /// - Given: Post and Comment instances
    /// - When:
    ///    - DataStore.save
    /// - Then:
    ///    - Data saved to the local store and synced to the cloud successfully.
    ///
    func testSavePostComment4V2() async throws {
        setup(withModels: PostComment4V2())
        try await assertDataStoreReady()
        try await assertQuerySuccess(modelType: Post4V2.self)
        
        let parent = Post4V2(title: "title")
        let child = Comment4V2(content: "content", post: parent)
        
        // Mutations
        try await assertMutationsParentChild(parent: parent, child: child)
    }

    /// Lazy Load the Comments from the Post object.
    /// This test is from the issue https://github.com/aws-amplify/amplify-swift/issues/2644
    /// The issue appears when using Amplify CLI v10.5.0 which defaults to CPK enabled for new projects.
    /// The swift models generated for this schema doesn't leverage CPK use case, however we are
    /// adding it here to ensure the CPK feature is backwards compatible for models with default identifiers.
    ///
    /// - Given: Post with a Comment
    /// - When:
    ///    - DataStore.query Post and traverse to the Comments
    /// - Then:
    ///    - Comments are lazy loaded.
    ///
    func testSavePostAndLazyLoadComments() async throws {
        setup(withModels: PostComment4V2())
        try await assertDataStoreReady()
        
        let parent = Post4V2(title: "title")
        let child = Comment4V2(content: "content", post: parent)
        
        // Mutations
        try await assertMutationsParentChild(parent: parent, child: child, shouldDeleteParent: false)
        
        guard let queriedPost = try await Amplify.DataStore.query(Post4V2.self, byId: parent.id) else {
            XCTFail("Failed to query post")
            return
        }
        try await queriedPost.comments!.fetch()
        XCTAssertEqual(queriedPost.comments?.count, 1)
        
        try await assertDeleteMutation(parent: parent, child: child)
    }
}

extension AWSDataStorePrimaryKeyPostComment4V2Test {
    struct PostComment4V2: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: Post4V2.self)
            ModelRegistry.register(modelType: Comment4V2.self)
        }
    }
}
