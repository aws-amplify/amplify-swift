//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSMobileClient
import AWSAPICategoryPlugin
@testable import Amplify
import AmplifyTestCommon

// swiftlint:disable type_body_length
class GraphQLModelBasedTests: XCTestCase {

    /*
     The backend is set up using this schema:
     ```
     type Post @model {
         id: ID!
         title: String!
         content: String!
         createdAt: AWSDateTime!
         updatedAt: AWSDateTime
         draft: Boolean
         rating: Float
         comments: [Comment] @connection(name: "PostComment")
         _version: Int
     }

     type Comment @model {
         id: ID!
         content: String!
         createdAt: AWSDateTime!
         post: Post @connection(name: "PostComment")
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
                 "ApiUrl": "https://5dxswtkp3favlnw2pvcmsp2mti.appsync-api.us-west-2.amazonaws.com/graphql",
                 "Region": "us-west-2",
                 "AuthMode": "API_KEY",
                 "ApiKey": "da2-bjcuhxgvgjadfpfh4fddd5lqmm",
                 "ClientDatabasePrefix": "modelbasedapi_API_KEY"
             }
         }
     }

     */

    static let modelBasedGraphQLWithAPIKey = "modelBasedGraphQLWithAPIKey"

    static let networkTimeout = TimeInterval(180)

    override func setUp() {
        Amplify.reset()
        let plugin = AWSAPICategoryPlugin()

        let apiConfig = APICategoryConfiguration(plugins: [
            "AWSAPICategoryPlugin": [
                GraphQLModelBasedTests.modelBasedGraphQLWithAPIKey: [
                    "Endpoint": "https://5dxswtkp3favlnw2pvcmsp2mti.appsync-api.us-west-2.amazonaws.com/graphql",
                    "Region": "us-west-2",
                    "AuthorizationType": "API_KEY",
                    "ApiKey": "da2-bjcuhxgvgjadfpfh4fddd5lqmm",
                    "EndpointType": "GraphQL"
                ],
            ]
        ])

        let amplifyConfig = AmplifyConfiguration(api: apiConfig)
        do {
            try Amplify.add(plugin: plugin)
            try Amplify.configure(amplifyConfig)

            // The API plugin should register the models into the model cache
            ModelRegistry.register(modelType: Comment.self)
            ModelRegistry.register(modelType: Post.self)

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
        _ = Amplify.API.query(from: Post.self, byId: uuid, listener: { event in
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

        _ = Amplify.API.query(from: Post.self, where: nil, listener: { event in
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
        guard createPost(id: uuid, title: uniqueTitle) != nil else {
            XCTFail("Failed to ensure at least one Post to be retrieved on the listQuery")
            return
        }

        let completeInvoked = expectation(description: "request completed")
        let post = Post.keys
        let predicate = post.title == uniqueTitle
        _ = Amplify.API.query(from: Post.self, where: predicate, listener: { event in
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
                XCTAssertEqual(singlePost.title, uniqueTitle)
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

        let post = Post(title: "title", content: "content")
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

        _ = Amplify.API.query(from: Post.self, byId: uuid, listener: { event in
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
        let updatedPost = Post(id: uuid, title: updatedTitle, content: post.content, createdAt: post.createdAt)
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

    func testOnCreateSubscriptionWithModel() {
        let connectedInvoked = expectation(description: "Connection established")
        let disconnectedInvoked = expectation(description: "Connection disconnected")
        let completedInvoked = expectation(description: "Completed invoked")
        let progressInvoked = expectation(description: "progress invoked")
        progressInvoked.expectedFulfillmentCount = 2

        let operation = Amplify.API.subscribe(from: Post.self, type: .onCreate) { event in
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

    func testOnUpdateSubscriptionWithModel() {
        let connectedInvoked = expectation(description: "Connection established")
        let disconnectedInvoked = expectation(description: "Connection disconnected")
        let completedInvoked = expectation(description: "Completed invoked")
        let progressInvoked = expectation(description: "progress invoked")

        let operation = Amplify.API.subscribe(from: Post.self, type: .onUpdate) { event in
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

    func testOnDeleteSubscriptionWithModel() {
        let connectedInvoked = expectation(description: "Connection established")
        let disconnectedInvoked = expectation(description: "Connection disconnected")
        let completedInvoked = expectation(description: "Completed invoked")
        let progressInvoked = expectation(description: "progress invoked")

        let operation = Amplify.API.subscribe(from: Post.self, type: .onDelete) { event in
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

    // MARK: Helpers

    func createPost(id: String, title: String) -> Post? {
        var result: Post?
        let completeInvoked = expectation(description: "request completed")

        let post = Post(id: id, title: title, content: "content")
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

    func updatePost(id: String, title: String) -> Post? {
        var result: Post?
        let completeInvoked = expectation(description: "request completed")

        let post = Post(id: id, title: title, content: "content")
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

    func deletePost(post: Post) -> Post? {
        var result: Post?
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
