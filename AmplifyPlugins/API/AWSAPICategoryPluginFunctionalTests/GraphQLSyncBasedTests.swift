//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSAPICategoryPlugin
@testable import Amplify
@testable import AmplifyTestCommon
import AWSPluginsCore

class GraphQLSyncBasedTests: XCTestCase {

    /*
     1. Set up with this schema
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
     }

     type Comment @model {
         id: ID!
         content: String!
         createdAt: AWSDateTime!
         post: Post @connection(name: "PostComment")
     }
     2. Sync Enabled
     */
    override func setUp() {
        Amplify.reset()
        let plugin = AWSAPIPlugin(modelRegistration: PostCommentModelRegistration())

        let apiConfig = APICategoryConfiguration(plugins: [
            "awsAPIPlugin": [
                "modelBasedSyncAPI": [
                    "endpointType": "GraphQL",
                    "endpoint": "https://3p5dcoozobblvawqfozyqkc2k4.appsync-api.us-west-2.amazonaws.com/graphql",
                    "region": "us-west-2",
                    "authorizationType": "API_KEY",
                    "apiKey": "da2-6x6j4sp4w5eyfmiuuvapehd6yi"
                ]
            ]
        ])

        let amplifyConfig = AmplifyConfiguration(api: apiConfig)
        do {
            try Amplify.add(plugin: plugin)
            try Amplify.configure(amplifyConfig)

            ModelRegistry.register(modelType: Comment.self)
            ModelRegistry.register(modelType: Post.self)

        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func tearDown() {
        Amplify.reset()
    }

    func testCreatePostThenUpdatePostWithNewVersion() {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        guard let post = createPost(id: uuid, title: title) else {
            XCTFail("Failed to create post with version 1")
            return
        }

        let completeInvoked = expectation(description: "request completed")
        var responseFromOperation: GraphQLResponse<MutationSync<AnyModel>>?
        let document = GraphQLSyncMutation(of: post, type: .update, version: 2)
        let request = GraphQLRequest(document: document.stringValue,
                                     variables: document.variables,
                                     responseType: MutationSync<AnyModel>.self,
                                     decodePath: document.decodePath)

        _ = Amplify.API.mutate(request: request) { event in
            defer {
                completeInvoked.fulfill()
            }
            switch event {
            case .completed(let graphQLResponse):
                responseFromOperation = graphQLResponse
            case .failed(let apiError):
                XCTFail("\(apiError)")
            default:
                XCTFail("Could not get data back")
            }
        }
        wait(for: [completeInvoked], timeout: GraphQLModelBasedTests.networkTimeout)

        guard let response = responseFromOperation else {
            XCTAssertNotNil(responseFromOperation)
            return
        }

        guard case .success(let mutationSync) = response else {
            switch response {
            case .success:
                break

            case .failure(let error):
                switch error {
                case .error(let errors):
                    XCTFail("errors: \(errors)")
                case .partial(let model, let errors):
                    XCTFail("partial: \(model), \(errors)")
                case .transformationError(let rawResponse, let apiError):
                    XCTFail("transformationError: \(rawResponse), \(apiError)")
                }
            }
            return
        }

        XCTAssertEqual(mutationSync.model["title"] as? String, post.title)
        XCTAssertEqual(mutationSync.model["content"] as? String, post.content)
        XCTAssertEqual(mutationSync.syncMetadata.version, 2)
    }

    func testQuerySyncWithLastSyncTime() {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        guard let createdPost = createPost(id: uuid, title: title) else {
            XCTFail("Failed to create post")
            return
        }

        let completeInvoked = expectation(description: "request completed")
        var responseFromOperation: GraphQLResponse<[MutationSync<AnyModel>]>?
        let post = Post.keys
        let predicate = post.id == uuid
        let document = GraphQLSyncQuery(from: Post.self, predicate: predicate, lastSync: 123)
        let request = GraphQLRequest(document: document.stringValue,
                                     variables: document.variables,
                                     responseType: [MutationSync<AnyModel>].self,
                                     decodePath: document.decodePath)

        _ = Amplify.API.query(request: request) { event in
            defer {
                completeInvoked.fulfill()
            }
            switch event {
            case .completed(let graphQLResponse):
                responseFromOperation = graphQLResponse
            case .failed(let error):
                print(error)
            default:
                XCTFail("Could not get data back")
            }
        }
        wait(for: [completeInvoked], timeout: GraphQLModelBasedTests.networkTimeout)

        guard let response = responseFromOperation else {
            XCTAssertNotNil(responseFromOperation)
            return
        }

        guard case .success(let mutationSync) = response else {
            switch response {
            case .success:
                break

            case .failure(let error):
                switch error {
                case .error(let errors):
                    XCTFail("errors: \(errors)")
                case .partial(let model, let errors):
                    XCTFail("partial: \(model), \(errors)")
                case .transformationError(let rawResponse, let apiError):
                    XCTFail("transformationError: \(rawResponse), \(apiError)")
                }
            }
            return
        }

        XCTAssertNotNil(mutationSync[0].model["title"] as? String)
        XCTAssertNotNil(mutationSync[0].model["content"] as? String)
        XCTAssert(mutationSync[0].syncMetadata.version != 0)
    }

    // MARK: Helpers

    func createPost(id: String, title: String) -> Post? {
        let post = Post(id: id, title: title, content: "content")
        return createPost(post: post)
    }

    func createPost(post: Post) -> Post? {
        var result: Post?
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

}
