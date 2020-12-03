//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSMobileClient
@testable import AWSAPICategoryPlugin
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSAPICategoryPluginTestCommon

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

    override func tearDown() {
        Amplify.reset()
    }

    // TODO: This test will fail until https://github.com/aws-amplify/amplify-ios/pull/885 is merged in
    func testListPostEditorByPost() {
        guard let post = createPost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard let user = createUser(username: "username") else {
            XCTFail("Could not create user")
            return
        }
        guard createPostEditor(post: post, editor: user) != nil else {
            XCTFail("Could not create user")
            return
        }
        let listPostEditorByPostIDCompleted = expectation(description: "list postEditor by postID complete")
        let predicateByPostId = PostEditor5.keys.post.eq(post.id)
        Amplify.API.query(request: .list(PostEditor5.self, where: predicateByPostId)) { result in
            switch result {
            case .success(let result):
                switch result {
                case .success(let projects):
                    print(projects)
                    listPostEditorByPostIDCompleted.fulfill()
                case .failure(let response):
                    XCTFail("Failed with: \(response)")
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [listPostEditorByPostIDCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    // TODO: This test will fail until https://github.com/aws-amplify/amplify-ios/pull/885 is merged in
    func testListPostEditorByUser() {
        guard let post = createPost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard let user = createUser(username: "username") else {
            XCTFail("Could not create user")
            return
        }
        guard createPostEditor(post: post, editor: user) != nil else {
            XCTFail("Could not create user")
            return
        }
        let listPostEditorByEditorIdCompleted = expectation(description: "list postEditor by editorID complete")
        let predicateByUserId = PostEditor5.keys.editor.eq(user.id)
        Amplify.API.query(request: .list(PostEditor5.self, where: predicateByUserId)) { result in
            switch result {
            case .success(let result):
                switch result {
                case .success(let projects):
                    print(projects)
                    listPostEditorByEditorIdCompleted.fulfill()
                case .failure(let response):
                    XCTFail("Failed with: \(response)")
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [listPostEditorByEditorIdCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    // TODO: complete this test with lazy loading of API (https://github.com/aws-amplify/amplify-ios/pull/845)
    func testGetPostThenLoadPostEditors() {
        guard let post = createPost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard let user = createUser(username: "username") else {
            XCTFail("Could not create user")
            return
        }
        guard let postEditor = createPostEditor(post: post, editor: user) else {
            XCTFail("Could not create user")
            return
        }
        let getPostCompleted = expectation(description: "get post complete")
        Amplify.API.query(request: .get(Post5.self, byId: post.id)) { result in
            switch result {
            case .success(let result):
                switch result {
                case .success(let queriedPost):
                    XCTAssertNotNil(queriedPost)
                    XCTAssertEqual(queriedPost!.id, post.id)
                    if let editors = queriedPost?.editors {
                        // TODO: Lazy load editors
                    }
                    getPostCompleted.fulfill()
                case .failure(let response):
                    XCTFail("Failed with: \(response)")
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [getPostCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    // TODO: complete this test with lazy loading of API (https://github.com/aws-amplify/amplify-ios/pull/845)
    func testGetUserThenLoadPosts() {
        guard let post = createPost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard let user = createUser(username: "username") else {
            XCTFail("Could not create user")
            return
        }
        guard let postEditor = createPostEditor(post: post, editor: user) else {
            XCTFail("Could not create user")
            return
        }
        let getUserCompleted = expectation(description: "get user complete")
        Amplify.API.query(request: .get(User5.self, byId: user.id)) { result in
            switch result {
            case .success(let result):
                switch result {
                case .success(let queriedUser):
                    XCTAssertNotNil(queriedUser)
                    XCTAssertEqual(queriedUser!.id, user.id)
                    if let posts = queriedUser?.posts {
                        // TODO: Lazy load editors
                    }
                    getUserCompleted.fulfill()
                case .failure(let response):
                    XCTFail("Failed with: \(response)")
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [getUserCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func createPost(id: String = UUID().uuidString, title: String) -> Post5? {
        let post = Post5(id: id, title: title)
        var result: Post5?
        let completeInvoked = expectation(description: "request completed")
        Amplify.API.mutate(request: .create(post)) { event in
            switch event {
            case .success(let data):
                switch data {
                case .success(let post):
                    result = post
                default:
                    XCTFail("Could not get data back")
                }
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }

    func createUser(id: String = UUID().uuidString, username: String) -> User5? {
        let user = User5(id: id, username: username)
        var result: User5?
        let completeInvoked = expectation(description: "request completed")
        Amplify.API.mutate(request: .create(user)) { event in
            switch event {
            case .success(let data):
                switch data {
                case .success(let comment):
                    result = comment
                default:
                    XCTFail("Could not get data back")
                }
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }

    func createPostEditor(id: String = UUID().uuidString, post: Post5, editor: User5) -> PostEditor5? {
        let postEditor = PostEditor5(id: id, post: post, editor: editor)
        var result: PostEditor5?
        let completeInvoked = expectation(description: "request completed")
        Amplify.API.mutate(request: .create(postEditor)) { event in
            switch event {
            case .success(let data):
                switch data {
                case .success(let comment):
                    result = comment
                default:
                    XCTFail("Could not get data back")
                }
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }
}
