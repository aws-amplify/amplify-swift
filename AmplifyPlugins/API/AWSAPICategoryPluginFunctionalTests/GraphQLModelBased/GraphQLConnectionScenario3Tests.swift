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
 (HasMany) A Post that can have many comments
 ```
 type Post3 @model {
   id: ID!
   title: String!
   comments: [Comment3] @connection(keyName: "byPost3", fields: ["id"])
 }

 type Comment3 @model
   @key(name: "byPost3", fields: ["postID", "content"]) {
   id: ID!
   postID: ID!
   content: String!
 }
 ```
 See https://docs.amplify.aws/cli/graphql-transformer/connection for more details
 */
class GraphQLConnectionScenario3Tests: XCTestCase {

    override func setUp() {
        do {
            Amplify.Logging.logLevel = .verbose
            try Amplify.add(plugin: AWSAPIPlugin())

            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(
                forResource: GraphQLModelBasedTests.amplifyConfiguration)
            try Amplify.configure(amplifyConfig)

            ModelRegistry.register(modelType: Comment3.self)
            ModelRegistry.register(modelType: Post3.self)

        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func tearDown() {
        Amplify.reset()
    }

    func testCreatAndGetComment() {
        guard let post = createPost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard let comment = createComment(postID: post.id, content: "content") else {
            XCTFail("Could not create comment")
            return
        }

        let getCommentCompleted = expectation(description: "get comment complete")
        Amplify.API.query(request: .get(Comment3.self, byId: comment.id)) { result in
            switch result {
            case .success(let result):
                switch result {
                case .success(let queriedCommentOptional):
                    guard let queriedComment = queriedCommentOptional else {
                        XCTFail("Could not get comment")
                        return
                    }
                    XCTAssertEqual(queriedComment.id, comment.id)
                    XCTAssertEqual(queriedComment.postID, post.id)
                    getCommentCompleted.fulfill()
                case .failure(let response):
                    XCTFail("Failed with: \(response)")
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [getCommentCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    // TODO: complete this test with lazy loading of API (https://github.com/aws-amplify/amplify-ios/pull/845)
    func testCreateCommentAndGetPostWithComments() {
        guard let post = createPost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard createComment(postID: post.id, content: "content") != nil else {
            XCTFail("Could not create comment")
            return
        }

        let getPostCompleted = expectation(description: "get post complete")
        Amplify.API.query(request: .get(Post3.self, byId: post.id)) { result in
            switch result {
            case .success(let result):
                switch result {
                case .success(let queriedPostOptional):
                    guard let queriedPost = queriedPostOptional else {
                        XCTFail("Could not get post")
                        return
                    }
                    XCTAssertEqual(queriedPost.id, post.id)
                    getPostCompleted.fulfill()
                // TODO: Load comments
                case .failure(let response):
                    XCTFail("Failed with: \(response)")
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [getPostCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func testUpdateComment() {
        guard let post = createPost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard var comment = createComment(postID: post.id, content: "content") else {
            XCTFail("Could not create comment")
            return
        }
        guard let anotherPost = createPost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        let updateCommentSuccessful = expectation(description: "update comment")
        comment.postID = anotherPost.id
        Amplify.API.mutate(request: .update(comment)) { result in
            switch result {
            case .success(let result):
                switch result {
                case .success(let updatedComment):
                    XCTAssertEqual(updatedComment.postID, anotherPost.id)
                case .failure(let response):
                    XCTFail("Failed with: \(response)")
                }
                updateCommentSuccessful.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [updateCommentSuccessful], timeout: TestCommonConstants.networkTimeout)
    }

    func testDeleteAndGetComment() {
        guard let post = createPost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard let comment = createComment(postID: post.id, content: "content") else {
            XCTFail("Could not create comment")
            return
        }

        let deleteCommentSuccessful = expectation(description: "delete comment")
        Amplify.API.mutate(request: .delete(comment)) { result in
            switch result {
            case .success(let result):
                switch result {
                case .success(let deletedComment):
                    XCTAssertEqual(deletedComment.postID, post.id)
                    deleteCommentSuccessful.fulfill()
                case .failure(let response):
                    XCTFail("Failed with: \(response)")
                }

            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [deleteCommentSuccessful], timeout: TestCommonConstants.networkTimeout)
        let getCommentAfterDeleteCompleted = expectation(description: "get comment after deleted complete")
        Amplify.API.query(request: .get(Comment3.self, byId: comment.id)) { result in
            switch result {
            case .success(let result):
                switch result {
                case .success(let comment):
                    guard comment == nil else {
                        XCTFail("Should be nil after deletion")
                        return
                    }
                    getCommentAfterDeleteCompleted.fulfill()
                case .failure(let response):
                    XCTFail("Failed with: \(response)")
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [getCommentAfterDeleteCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func testListCommentsByPostID() {
        guard let post = createPost(title: "title") else {
            XCTFail("Could not create post")
            return
        }
        guard createComment(postID: post.id, content: "content") != nil else {
            XCTFail("Could not create comment")
            return
        }
        let listCommentByPostIDCompleted = expectation(description: "list projects completed")
        let predicate = Comment3.keys.postID.eq(post.id)
        Amplify.API.query(request: .list(Comment3.self, where: predicate)) { result in
            switch result {
            case .success(let result):
                switch result {
                case .success(let projects):
                    print(projects)
                    listCommentByPostIDCompleted.fulfill()
                case .failure(let response):
                    XCTFail("Failed with: \(response)")
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [listCommentByPostIDCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func createPost(id: String = UUID().uuidString, title: String) -> Post3? {
        let post = Post3(id: id, title: title)
        var result: Post3?
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

    func createComment(id: String = UUID().uuidString, postID: String, content: String) -> Comment3? {
        let comment = Comment3(id: id, postID: postID, content: content)
        var result: Comment3?
        let completeInvoked = expectation(description: "request completed")
        Amplify.API.mutate(request: .create(comment)) { event in
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
