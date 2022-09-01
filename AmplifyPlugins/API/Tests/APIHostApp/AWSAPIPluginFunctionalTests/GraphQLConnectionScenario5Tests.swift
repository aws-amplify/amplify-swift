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

/*
 (Many-to-many) Using two one-to-many connections, an @key, and a joining @model, you can create a many-to-many
 connection.
 ```
 type Post5 @model {
   id: ID!
   title: String!
   editors: [PostEditor5] @connection(keyName: "byPost5", fields: ["id"])
 }

 # Create a join model
 type PostEditor5
   @model
   @key(name: "byPost5", fields: ["postID", "editorID"])
   @key(name: "byEditor5", fields: ["editorID", "postID"]) {
   id: ID!
   postID: ID!
   editorID: ID!
   post: Post5! @connection(fields: ["postID"])
   editor: User5! @connection(fields: ["editorID"])
 }

 type User5 @model {
   id: ID!
   username: String!
   posts: [PostEditor5] @connection(keyName: "byEditor5", fields: ["id"])
 }
 ```
 See https://docs.amplify.aws/cli/graphql-transformer/connection for more details.
 */
class GraphQLConnectionScenario5Tests: XCTestCase {

    override func setUp() {
        do {
            Amplify.Logging.logLevel = .verbose
            try Amplify.add(plugin: AWSAPIPlugin())

            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(
                forResource: GraphQLModelBasedTests.amplifyConfiguration)
            try Amplify.configure(amplifyConfig)

            ModelRegistry.register(modelType: Post5.self)
            ModelRegistry.register(modelType: PostEditor5.self)
            ModelRegistry.register(modelType: User5.self)

        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func tearDown() async throws {
        await Amplify.reset()
    }

    func testListPostEditorByPost() async throws {
        guard let post = try await createPost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard let user = try await createUser(username: "username") else {
            XCTFail("Could not create user")
            return
        }
        guard try await createPostEditor(post: post, editor: user) != nil else {
            XCTFail("Could not create user")
            return
        }
        let predicateByPostId = PostEditor5.keys.post.eq(post.id)
        let result = try await Amplify.API.query(request: .list(PostEditor5.self, where: predicateByPostId))
        switch result {
        case .success(let projects):
            XCTAssertNotNil(projects)
        case .failure(let response):
            XCTFail("Failed with: \(response)")
        }
    }

    func testListPostEditorByUser() async throws {
        guard let post = try await createPost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard let user = try await createUser(username: "username") else {
            XCTFail("Could not create user")
            return
        }
        guard try await createPostEditor(post: post, editor: user) != nil else {
            XCTFail("Could not create user")
            return
        }
        let predicateByUserId = PostEditor5.keys.editor.eq(user.id)
        let result = try await Amplify.API.query(request: .list(PostEditor5.self, where: predicateByUserId))
        switch result {
        case .success(let projects):
            XCTAssertNotNil(projects)
        case .failure(let response):
            XCTFail("Failed with: \(response)")
        }
    }

    // Create a Post and a User, Create a PostEditor with the post and user
    // Get the post and fetch the PostEditors for that post
    // The Posteditor contains the user which is connected the post
    func testGetPostThenFetchPostEditorsToRetrieveUser() async throws {
        guard let post = try await createPost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard let user = try await createUser(username: "username") else {
            XCTFail("Could not create user")
            return
        }
        guard try await createPostEditor(post: post, editor: user) != nil else {
            XCTFail("Could not create user")
            return
        }
        let getPostCompleted = expectation(description: "get post complete")
        let fetchPostEditorCompleted = expectation(description: "fetch postEditors complete")
        var results: List<PostEditor5>?
        let response = try await Amplify.API.query(request: .get(Post5.self, byId: post.id))
        switch response {
        case .success(let queriedPostOptional):
            guard let queriedPost = queriedPostOptional else {
                XCTFail("Could not get post")
                return
            }
            XCTAssertEqual(queriedPost.id, post.id)
            getPostCompleted.fulfill()
            guard let editors = queriedPost.editors else {
                XCTFail("Could not get postEditors")
                return
            }
            try await editors.fetch()
            results = editors
            fetchPostEditorCompleted.fulfill()
        case .failure(let response):
            XCTFail("Failed with: \(response)")
        }
        wait(for: [getPostCompleted, fetchPostEditorCompleted], timeout: TestCommonConstants.networkTimeout)
        guard var subsequentResults = results else {
            XCTFail("Could not get first results")
            return
        }
        var resultsArray: [PostEditor5] = []
        resultsArray.append(contentsOf: subsequentResults)
        while subsequentResults.hasNextPage() {
            let listResult = try await subsequentResults.getNextPage()
            subsequentResults = listResult
            resultsArray.append(contentsOf: subsequentResults)
        }
        XCTAssertEqual(resultsArray.count, 1)
        guard let postEditor = resultsArray.first else {
            XCTFail("Could not get editor")
            return
        }
        XCTAssertEqual(postEditor.editor.id, user.id)
    }

    // Create two posts (`post1` and `post2`) and a user
    // create first PostEditor with the `post1` and user and create second postEditor with `post2` and user.
    // Get the user and fetch the PostEditors for that user
    // The PostEditors should contain the two posts `post1` and `post2`
    func testGetUserThenFetchPostEditorsToRetrievePosts() async throws {
        guard let post1 = try await createPost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard let post2 = try await createPost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard let user = try await createUser(username: "username") else {
            XCTFail("Could not create user")
            return
        }
        guard try await createPostEditor(post: post1, editor: user) != nil else {
            XCTFail("Could not create postEditor with `post1`")
            return
        }
        guard try await createPostEditor(post: post2, editor: user) != nil else {
            XCTFail("Could not create postEditor with `post2`")
            return
        }
        let getUserCompleted = expectation(description: "get user complete")
        let fetchPostEditorCompleted = expectation(description: "fetch postEditors complete")
        var results: List<PostEditor5>?
        let response = try await Amplify.API.query(request: .get(User5.self, byId: user.id))
        switch response {
        case .success(let queriedUserOptional):
            guard let queriedUser = queriedUserOptional else {
                XCTFail("Could not get post")
                return
            }
            XCTAssertEqual(queriedUser.id, user.id)
            getUserCompleted.fulfill()
            guard let posts = queriedUser.posts else {
                XCTFail("Could not get postEditors")
                return
            }
            try await posts.fetch()
            results = posts
            fetchPostEditorCompleted.fulfill()
        case .failure(let response):
            XCTFail("Failed with: \(response)")
        }
        wait(for: [getUserCompleted, fetchPostEditorCompleted], timeout: TestCommonConstants.networkTimeout)

        guard var subsequentResults = results else {
            XCTFail("Could not get first results")
            return
        }
        var resultsArray: [PostEditor5] = []
        resultsArray.append(contentsOf: subsequentResults)
        while subsequentResults.hasNextPage() {
            let listResult = try await subsequentResults.getNextPage()
            subsequentResults = listResult
            resultsArray.append(contentsOf: subsequentResults)
        }
        XCTAssertEqual(resultsArray.count, 2)
        XCTAssertTrue(resultsArray.contains(where: { (postEditor) -> Bool in
            postEditor.post.id == post1.id
        }))
        XCTAssertTrue(resultsArray.contains(where: { (postEditor) -> Bool in
            postEditor.post.id == post2.id
        }))
    }

    func createPost(id: String = UUID().uuidString, title: String) async throws -> Post5? {
        let post = Post5(id: id, title: title)
        let data = try await Amplify.API.mutate(request: .create(post))
        switch data {
        case .success(let post):
            return post
        case .failure(let error):
            throw error
        }
    }

    func createUser(id: String = UUID().uuidString, username: String) async throws -> User5? {
        let user = User5(id: id, username: username)
        let data = try await Amplify.API.mutate(request: .create(user))
        switch data {
        case .success(let user):
            return user
        case .failure(let error):
            throw error
        }
    }

    func createPostEditor(id: String = UUID().uuidString, post: Post5, editor: User5) async throws -> PostEditor5? {
        let postEditor = PostEditor5(id: id, post: post, editor: editor)
        let data = try await Amplify.API.mutate(request: .create(postEditor))
        switch data {
        case .success(let postEditor):
            return postEditor
        case .failure(let error):
            throw error
        }
    }
}
