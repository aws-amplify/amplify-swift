//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSMobileClient
@testable import AWSAPICategoryPlugin
@testable import Amplify
@testable import AmplifyTestCommon

// swiftlint:disable type_body_length
class GraphQLModelBasedTests: XCTestCase {

    /*
     The backend is set up using this schema:
     ```
     type PostNoSync @model {
         id: ID!
         title: String!
         content: String!
         createdAt: AWSDateTime!
         updatedAt: AWSDateTime
         draft: Boolean
         rating: Float
         commentNoSyncs: [CommentNoSync] @connection(name: "PostNoSyncCommentNoSync")
     }

     type CommentNoSync @model {
         id: ID!
         content: String!
         createdAt: AWSDateTime!
         postNoSync: PostNoSync @connection(name: "PostNoSyncCommentNoSync")
     }

     ```

     Bootstrapping backend

     - for subscriptions, this was done in us-west-2 for the new gogi endpoints.
     - use the schema when adding graphQL API
     - choose API key

     Example CLI workflow:
     `amplify add api`
        ? Please select from one of the below mentioned services `GraphQL`
        ? Provide API name: `modelbasedapi`
        ? Choose the default authorization type for the API `API key`
        ? Enter a description for the API key: `apikey`
        ? After how many days from now the API key should expire (1-365): `180`
        ? Do you want to configure advanced settings for the GraphQL API `No, I am done.`
        ? Do you have an annotated GraphQL schema? `Yes`
        ? Provide your schema file path: schema.graphql

     `amplify push`
        ? Do you want to generate code for your newly created GraphQL API `Yes`
        ? Enter the file name pattern of graphql queries, mutations and subscriptions `graphql/**/*.graphql`
        ? Do you want to generate/update all possible GraphQL operations - queries, mutations and subscriptions `Yes`
        ? Enter maximum statement depth [increase from default if your schema is deeply nested] `2`
        ? Enter the file name for the generated code `API.swift`


    The models exist in AmplifyTestCommon/Models/Post.swift and Comment.Swift, we use these for testing

     {
         "UserAgent": "aws-amplify/cli",
         "Version": "0.1.0",
         "IdentityManager": {
             "Default": {}
         },
         "AppSync": {
             "Default": {
                 "ApiUrl": "https://xxxx.appsync-api.us-west-2.amazonaws.com/graphql",
                 "Region": "us-west-2",
                 "AuthMode": "API_KEY",
                 "apiKey": "da2-xxx",
                 "ClientDatabasePrefix": "modelbasedapi_API_KEY"
             }
         }
     }

     */

    static let modelBasedGraphQLWithAPIKey = "modelBasedGraphQLWithAPIKey"

    static let networkTimeout = TimeInterval(180)

    override func setUp() {
        Amplify.reset()
        let plugin = AWSAPIPlugin(modelRegistration: NotSyncablePostCommentModelRegistration())

        let apiConfig = APICategoryConfiguration(plugins: [
            "awsAPIPlugin": [
                GraphQLModelBasedTests.modelBasedGraphQLWithAPIKey: [
                    "endpoint": "https://xxxx.appsync-api.us-west-2.amazonaws.com/graphql",
                    "region": "us-west-2",
                    "authorizationType": "API_KEY",
                    "apiKey": "da2-xx",
                    "endpointType": "GraphQL"
                ]
            ]
        ])

        let amplifyConfig = AmplifyConfiguration(api: apiConfig)
        do {
            try Amplify.add(plugin: plugin)
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func tearDown() {
        Amplify.reset()
    }

    func testQuerySinglePostWithModel() {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        guard let post = createPost(id: uuid, title: title) else {
            XCTFail("Failed to set up test")
            return
        }

        let completeInvoked = expectation(description: "request completed")
        _ = Amplify.API.query(from: PostNoSync.self, byId: uuid, listener: { event in
            switch event {
            case .completed(let graphQLResponse):
                guard case let .success(data) = graphQLResponse else {
                    XCTFail("Missing successful response")
                    return
                }
                guard let resultPost = data else {
                    XCTFail("Missing post from querySingle")
                    return
                }

                XCTAssertEqual(resultPost.id, post.id)
                XCTAssertEqual(resultPost.title, title)
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Unexpected .failed event: \(error)")
            default:
                XCTFail("Unexpected event: \(event)")
            }
        })

        wait(for: [completeInvoked], timeout: GraphQLModelBasedTests.networkTimeout)
    }

    func testListQueryWithModel() {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        guard createPost(id: uuid, title: title) != nil else {
            XCTFail("Failed to ensure at least one Post to be retrieved on the listQuery")
            return
        }

        let completeInvoked = expectation(description: "request completed")

        _ = Amplify.API.query(from: PostNoSync.self, where: nil, listener: { event in
            switch event {
            case .completed(let graphQLResponse):
                guard case let .success(posts) = graphQLResponse else {
                    XCTFail("Missing successful response")
                    return
                }
                XCTAssertTrue(!posts.isEmpty)
                print(posts)
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Unexpected .failed event: \(error)")
            default:
                XCTFail("Unexpected event: \(event)")
            }
        })

        wait(for: [completeInvoked], timeout: GraphQLModelBasedTests.networkTimeout)
    }

    func testListQueryWithPredicate() {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let uniqueTitle = testMethodName + uuid + "Title"
        let createdPost = PostNoSync(id: uuid,
                                     title: uniqueTitle,
                                     content: "content",
                                     rating: 12.3,
                                     draft: true,
                                     _version: 1)
        guard createPost(post: createdPost) != nil else {
            XCTFail("Failed to ensure at least one Post to be retrieved on the listQuery")
            return
        }

        let completeInvoked = expectation(description: "request completed")
        let post = PostNoSync.keys
        let predicate = post.id == uuid &&
            post.title == uniqueTitle &&
            post.content == "content" &&
            post.createdAt == createdPost.createdAt &&
            post.rating == 12.3 &&
            post.draft == true

        _ = Amplify.API.query(from: PostNoSync.self, where: predicate, listener: { event in
            switch event {
            case .completed(let graphQLResponse):
                guard case let .success(posts) = graphQLResponse else {
                    XCTFail("Missing successful response")
                    return
                }
                XCTAssertEqual(posts.count, 1)
                guard let singlePost = posts.first else {
                    XCTFail("Should only have a single post with the unique title")
                    return
                }
                XCTAssertEqual(singlePost.id, uuid)
                XCTAssertEqual(singlePost.title, uniqueTitle)
                XCTAssertEqual(singlePost.content, "content")
                XCTAssertEqual(singlePost.createdAt.iso8601String, createdPost.createdAt.iso8601String)
                XCTAssertEqual(singlePost.rating, 12.3)
                XCTAssertEqual(singlePost.draft, true)
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Unexpected .failed event: \(error)")
            default:
                XCTFail("Unexpected event: \(event)")
            }
        })

        wait(for: [completeInvoked], timeout: GraphQLModelBasedTests.networkTimeout)
    }

    func testCreatPostWithModel() {
        let completeInvoked = expectation(description: "request completed")

        let post = PostNoSync(title: "title", content: "content")
        _ = Amplify.API.mutate(of: post, type: .create, listener: { event in
            switch event {
            case .completed(let data):
                switch data {
                case .success(let post):
                    XCTAssertEqual(post.title, "title")
                    completeInvoked.fulfill()
                case .failure(let error):
                    XCTFail("Unexpected response with error \(error)")
                }
            case .failed(let error):
                print(error)
            default:
                XCTFail("Could not get data back")
            }
        })
        wait(for: [completeInvoked], timeout: GraphQLModelBasedTests.networkTimeout)
    }

    func testCreateCommentWithModel() {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        guard let createdPost = createPost(id: uuid, title: title) else {
            XCTFail("Failed to create a Post.")
            return
        }

        let completeInvoked = expectation(description: "request completed")
        let comment = CommentNoSync(content: "commentContent", postNoSync: createdPost)
        _ = Amplify.API.mutate(of: comment, type: .create, listener: { event in
            switch event {
            case .completed(let data):
                switch data {
                case .success(let comment):
                    XCTAssertEqual(comment.content, "commentContent")
                    XCTAssertNotNil(comment.postNoSync)
                    XCTAssertEqual(comment.postNoSync.id, uuid)
                    completeInvoked.fulfill()
                case .failure(let error):
                    XCTFail("Unexpected response with error \(error)")
                }
            case .failed(let error):
                print(error)
            default:
                XCTFail("Could not get data back")
            }
        })
        wait(for: [completeInvoked], timeout: GraphQLModelBasedTests.networkTimeout)
    }

    func testDeletePostWithModel() {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        guard let post = createPost(id: uuid, title: title) else {
            XCTFail("Failed to ensure at least one Post to be retrieved on the listQuery")
            return
        }

        let completeInvoked = expectation(description: "request completed")

        _ = Amplify.API.mutate(of: post, type: .delete, listener: { event in
            switch event {
            case .completed(let data):
                switch data {
                case .success(let post):
                    XCTAssertEqual(post.title, title)
                case .failure(let error):
                    print(error)
                }
                completeInvoked.fulfill()
            case .failed(let error):
                print(error)
            default:
                XCTFail("Could not get data back")
            }
        })
        wait(for: [completeInvoked], timeout: GraphQLModelBasedTests.networkTimeout)

        let queryComplete = expectation(description: "query complete")

        _ = Amplify.API.query(from: PostNoSync.self, byId: uuid, listener: { event in
            switch event {
            case .completed(let graphQLResponse):
                guard case let .success(post) = graphQLResponse else {
                    XCTFail("Missing successful response")
                    return
                }
                XCTAssertNil(post)
                queryComplete.fulfill()
            case .failed(let error):
                XCTFail("Unexpected .failed event: \(error)")
            default:
                XCTFail("Unexpected event: \(event)")
            }
        })

        wait(for: [queryComplete], timeout: GraphQLModelBasedTests.networkTimeout)
    }

    func testUpdatePostWithModel() {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        guard let post = createPost(id: uuid, title: title) else {
            XCTFail("Failed to ensure at least one Post to be retrieved on the listQuery")
            return
        }
        let updatedTitle = title + "Updated"
        let updatedPost = PostNoSync(id: uuid, title: updatedTitle, content: post.content, createdAt: post.createdAt)
        let completeInvoked = expectation(description: "request completed")
        _ = Amplify.API.mutate(of: updatedPost, type: .update, listener: { event in
            switch event {
            case .completed(let data):
                switch data {
                case .success(let post):
                    XCTAssertEqual(post.title, updatedTitle)
                case .failure(let error):
                    print(error)
                }
                completeInvoked.fulfill()
            case .failed(let error):
                print(error)
            default:
                XCTFail("Could not get data back")
            }
        })
        wait(for: [completeInvoked], timeout: GraphQLModelBasedTests.networkTimeout)
    }

    func testOnCreatePostSubscriptionWithModel() {
        let connectedInvoked = expectation(description: "Connection established")
        let disconnectedInvoked = expectation(description: "Connection disconnected")
        let completedInvoked = expectation(description: "Completed invoked")
        let progressInvoked = expectation(description: "progress invoked")
        progressInvoked.expectedFulfillmentCount = 2

        let operation = Amplify.API.subscribe(from: PostNoSync.self, type: .onCreate) { event in
            switch event {
            case .inProcess(let graphQLResponse):
                print(graphQLResponse)
                switch graphQLResponse {
                case .connection(let state):
                    switch state {
                    case .connecting:
                        break
                    case .connected:
                        connectedInvoked.fulfill()
                    case .disconnected:
                        disconnectedInvoked.fulfill()
                    }

                case .data(let graphQLResponse):
                    progressInvoked.fulfill()
                }
            case .failed(let error):
                print("Unexpected .failed event: \(error)")
            case .completed:
                completedInvoked.fulfill()
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }
        XCTAssertNotNil(operation)
        wait(for: [connectedInvoked], timeout: GraphQLModelBasedTests.networkTimeout)
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"

        guard createPost(id: uuid, title: title) != nil else {
            XCTFail("Failed to create post")
            return
        }

        let uuid2 = UUID().uuidString
        guard createPost(id: uuid2, title: title) != nil else {
            XCTFail("Failed to create post")
            return
        }

        wait(for: [progressInvoked], timeout: GraphQLModelBasedTests.networkTimeout)
        operation.cancel()
        wait(for: [disconnectedInvoked, completedInvoked], timeout: GraphQLModelBasedTests.networkTimeout)
        XCTAssertTrue(operation.isFinished)
    }

    func testOnUpdatePostSubscriptionWithModel() {
        let connectedInvoked = expectation(description: "Connection established")
        let disconnectedInvoked = expectation(description: "Connection disconnected")
        let completedInvoked = expectation(description: "Completed invoked")
        let progressInvoked = expectation(description: "progress invoked")

        let operation = Amplify.API.subscribe(from: PostNoSync.self, type: .onUpdate) { event in
            switch event {
            case .inProcess(let graphQLResponse):
                print(graphQLResponse)
                switch graphQLResponse {
                case .connection(let state):
                    switch state {
                    case .connecting:
                        break
                    case .connected:
                        connectedInvoked.fulfill()
                    case .disconnected:
                        disconnectedInvoked.fulfill()
                    }

                case .data(let graphQLResponse):
                    progressInvoked.fulfill()
                }
            case .failed(let error):
                print("Unexpected .failed event: \(error)")
            case .completed:
                completedInvoked.fulfill()
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }
        XCTAssertNotNil(operation)
        wait(for: [connectedInvoked], timeout: GraphQLModelBasedTests.networkTimeout)
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"

        guard createPost(id: uuid, title: title) != nil else {
            XCTFail("Failed to create post")
            return
        }

        guard updatePost(id: uuid, title: title) != nil else {
            XCTFail("Failed to update post")
            return
        }

        wait(for: [progressInvoked], timeout: GraphQLModelBasedTests.networkTimeout)
        operation.cancel()
        wait(for: [disconnectedInvoked, completedInvoked], timeout: GraphQLModelBasedTests.networkTimeout)
        XCTAssertTrue(operation.isFinished)
    }

    func testOnDeletePostSubscriptionWithModel() {
        let connectedInvoked = expectation(description: "Connection established")
        let disconnectedInvoked = expectation(description: "Connection disconnected")
        let completedInvoked = expectation(description: "Completed invoked")
        let progressInvoked = expectation(description: "progress invoked")

        let operation = Amplify.API.subscribe(from: PostNoSync.self, type: .onDelete) { event in
            switch event {
            case .inProcess(let graphQLResponse):
                print(graphQLResponse)
                switch graphQLResponse {
                case .connection(let state):
                    switch state {
                    case .connecting:
                        break
                    case .connected:
                        connectedInvoked.fulfill()
                    case .disconnected:
                        disconnectedInvoked.fulfill()
                    }

                case .data(let graphQLResponse):
                    progressInvoked.fulfill()
                }
            case .failed(let error):
                print("Unexpected .failed event: \(error)")
            case .completed:
                completedInvoked.fulfill()
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }
        XCTAssertNotNil(operation)
        wait(for: [connectedInvoked], timeout: GraphQLModelBasedTests.networkTimeout)
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"

        guard let post = createPost(id: uuid, title: title) else {
            XCTFail("Failed to create post")
            return
        }

        guard deletePost(post: post) != nil else {
            XCTFail("Failed to update post")
            return
        }

        wait(for: [progressInvoked], timeout: GraphQLModelBasedTests.networkTimeout)
        operation.cancel()
        wait(for: [disconnectedInvoked, completedInvoked], timeout: GraphQLModelBasedTests.networkTimeout)
        XCTAssertTrue(operation.isFinished)
    }

    func testOnCreateCommentSubscriptionWithModel() {
        let connectedInvoked = expectation(description: "Connection established")
        let disconnectedInvoked = expectation(description: "Connection disconnected")
        let completedInvoked = expectation(description: "Completed invoked")
        let progressInvoked = expectation(description: "progress invoked")

        let operation = Amplify.API.subscribe(from: CommentNoSync.self, type: .onCreate) { event in
            switch event {
            case .inProcess(let graphQLResponse):
                print(graphQLResponse)
                switch graphQLResponse {
                case .connection(let state):
                    switch state {
                    case .connecting:
                        break
                    case .connected:
                        connectedInvoked.fulfill()
                    case .disconnected:
                        disconnectedInvoked.fulfill()
                    }

                case .data(let graphQLResponse):
                    progressInvoked.fulfill()
                }
            case .failed(let error):
                print("Unexpected .failed event: \(error)")
            case .completed:
                completedInvoked.fulfill()
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }
        XCTAssertNotNil(operation)
        wait(for: [connectedInvoked], timeout: GraphQLModelBasedTests.networkTimeout)
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"

        guard let createdPost = createPost(id: uuid, title: title) else {
            XCTFail("Failed to create post")
            return
        }

        guard createComment(content: "content", post: createdPost) != nil else {
            XCTFail("Failed to create comment with post")
            return
        }

        wait(for: [progressInvoked], timeout: GraphQLModelBasedTests.networkTimeout)
        operation.cancel()
        wait(for: [disconnectedInvoked, completedInvoked], timeout: GraphQLModelBasedTests.networkTimeout)
        XCTAssertTrue(operation.isFinished)
    }

    // MARK: Helpers

    func createPost(id: String, title: String) -> PostNoSync? {
        let post = PostNoSync(id: id, title: title, content: "content")
        return createPost(post: post)
    }

    func createComment(content: String, post: PostNoSync) -> CommentNoSync? {
        let comment = CommentNoSync(content: content, postNoSync: post)
        return createComment(comment: comment)
    }

    func createPost(post: PostNoSync) -> PostNoSync? {
        var result: PostNoSync?
        let completeInvoked = expectation(description: "request completed")

        _ = Amplify.API.mutate(of: post, type: .create, listener: { event in
            switch event {
            case .completed(let data):
                switch data {
                case .success(let post):
                    result = post
                default:
                    XCTFail("Could not get data back")
                }
                completeInvoked.fulfill()
            case .failed(let error):
                print(error)
            default:
                XCTFail("Could not get data back")
            }
        })
        wait(for: [completeInvoked], timeout: GraphQLModelBasedTests.networkTimeout)
        return result
    }

    func createComment(comment: CommentNoSync) -> CommentNoSync? {
        var result: CommentNoSync?
        let completeInvoked = expectation(description: "request completed")

        _ = Amplify.API.mutate(of: comment, type: .create, listener: { event in
            switch event {
            case .completed(let data):
                switch data {
                case .success(let comment):
                    result = comment
                default:
                    XCTFail("Could not get data back")
                }
                completeInvoked.fulfill()
            case .failed(let error):
                print(error)
            default:
                XCTFail("Could not get data back")
            }
        })
        wait(for: [completeInvoked], timeout: GraphQLModelBasedTests.networkTimeout)
        return result
    }

    func updatePost(id: String, title: String) -> PostNoSync? {
        var result: PostNoSync?
        let completeInvoked = expectation(description: "request completed")

        let post = PostNoSync(id: id, title: title, content: "content")
        _ = Amplify.API.mutate(of: post, type: .update, listener: { event in
            switch event {
            case .completed(let data):
                switch data {
                case .success(let post):
                    result = post
                default:
                    XCTFail("Could not get data back")
                }
                completeInvoked.fulfill()
            case .failed(let error):
                print(error)
            default:
                XCTFail("Could not get data back")
            }
        })
        wait(for: [completeInvoked], timeout: GraphQLModelBasedTests.networkTimeout)
        return result
    }

    func deletePost(post: PostNoSync) -> PostNoSync? {
        var result: PostNoSync?
        let completeInvoked = expectation(description: "request completed")

        _ = Amplify.API.mutate(of: post, type: .delete, listener: { event in
            switch event {
            case .completed(let data):
                switch data {
                case .success(let post):
                    result = post
                default:
                    XCTFail("Could not get data back")
                }
                completeInvoked.fulfill()
            case .failed(let error):
                print(error)
            default:
                XCTFail("Could not get data back")
            }
        })
        wait(for: [completeInvoked], timeout: GraphQLModelBasedTests.networkTimeout)
        return result
    }
}
