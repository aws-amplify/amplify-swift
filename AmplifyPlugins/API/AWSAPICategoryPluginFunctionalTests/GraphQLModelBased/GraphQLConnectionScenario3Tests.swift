//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
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

    func testQuerySinglePost() {
        guard let post = createPost(title: "title") else {
            XCTFail("Failed to set up test")
            return
        }

        let requestInvokedSuccessfully = expectation(description: "request completed")
        _ = Amplify.API.query(request: .get(Post3.self, byId: post.id)) { event in
            switch event {
            case .success(let graphQLResponse):
                guard case let .success(data) = graphQLResponse else {
                    XCTFail("Missing successful response")
                    return
                }
                guard let resultPost = data else {
                    XCTFail("Missing post from query")
                    return
                }

                XCTAssertEqual(resultPost.id, post.id)
                requestInvokedSuccessfully.fulfill()
            case .failure(let error):
                XCTFail("Unexpected .failed event: \(error)")
            }
        }

        wait(for: [requestInvokedSuccessfully], timeout: TestCommonConstants.networkTimeout)
    }

    // Create a post and a comment for the post
    // Retrieve the comment and ensure that the comment is associated with the correct post
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

    // Create a post and a comment associated with that post.
    // Create another post that will be used to update the existing comment
    // Update the existing comment to point to the other post
    // Expect that the queried comment is associated with the other post
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

    func testUpdateExistingPost() {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        guard var post = createPost(id: uuid, title: title) else {
            XCTFail("Failed to ensure at least one Post to be retrieved on the listQuery")
            return
        }
        let updatedTitle = title + "Updated"
        post.title = updatedTitle
        let requestInvokedSuccessfully = expectation(description: "request completed")
        _ = Amplify.API.mutate(request: .update(post)) { event in
            switch event {
            case .success(let data):
                switch data {
                case .success(let post):
                    XCTAssertEqual(post.title, updatedTitle)
                case .failure(let error):
                    XCTFail("\(error)")
                }
                requestInvokedSuccessfully.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [requestInvokedSuccessfully], timeout: TestCommonConstants.networkTimeout)
    }

    func testDeleteExistingPost() {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        guard let post = createPost(id: uuid, title: title) else {
            XCTFail("Could not create post")
            return
        }

        let requestInvokedSuccessfully = expectation(description: "request completed")

        _ = Amplify.API.mutate(request: .delete(post)) { event in
            switch event {
            case .success(let data):
                switch data {
                case .success(let post):
                    XCTAssertEqual(post.title, title)
                case .failure(let error):
                    XCTFail("\(error)")
                }
                requestInvokedSuccessfully.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [requestInvokedSuccessfully], timeout: TestCommonConstants.networkTimeout)

        let queryComplete = expectation(description: "query complete")

        _ = Amplify.API.query(request: .get(Post3.self, byId: uuid)) { event in
            switch event {
            case .success(let graphQLResponse):
                guard case let .success(post) = graphQLResponse else {
                    XCTFail("Missing successful response")
                    return
                }
                XCTAssertNil(post)
                queryComplete.fulfill()
            case .failure(let error):
                XCTFail("Unexpected .failed event: \(error)")
            }
        }

        wait(for: [queryComplete], timeout: TestCommonConstants.networkTimeout)
    }

    // Create a post and then create a comment associated with the post
    // Delete the comment and then query for the comment
    // Expected query should return `nil` comment
    // swiftlint:disable:next cyclomatic_complexity
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
}
