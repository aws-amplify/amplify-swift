//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSAPICategoryPlugin
@testable import Amplify
import AmplifyTestCommon

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
        let plugin = AWSAPIPlugin()

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

        let document = GraphQLSyncMutation(of: post, type: .update, version: 2)
        let request = GraphQLRequest(document: document.stringValue,
                                     variables: document.variables,
                                     responseType: String.self,
                                     decodePath: document.decodePath)

        _ = Amplify.API.mutate(request: request) { event in
            switch event {
            case .completed(let data):
                switch data {
                case .success(let stringResult):
                    XCTAssertTrue(stringResult.contains("\"_version\":2"))
                    completeInvoked.fulfill()
                case .failure(let error):
                    XCTFail("Unexpected response with error \(error)")
                }
            case .failed(let error):
                print(error)
            default:
                XCTFail("Could not get data back")
            }
        }
        wait(for: [completeInvoked], timeout: GraphQLModelBasedTests.networkTimeout)
    }

    func testQuerySyncWithLastSyncTime() {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let title = testMethodName + "Title"
        guard createPost(id: uuid, title: title) != nil else {
            XCTFail("Failed to create post")
            return
        }

        let completeInvoked = expectation(description: "request completed")

        let post = Post.keys
        let predicate = post.id == uuid
        let document = GraphQLSyncQuery(from: Post.self, predicate: predicate, lastSync: 123)
        let request = GraphQLRequest(document: document.stringValue,
                                     variables: document.variables,
                                     responseType: String.self,
                                     decodePath: document.decodePath)

        _ = Amplify.API.mutate(request: request) { event in
            switch event {
            case .completed(let data):
                switch data {
                case .success(let stringResultList):
                    XCTAssertTrue(stringResultList.contains("lastChangedAt"))
                    print(stringResultList)
                    completeInvoked.fulfill()
                case .failure(let error):
                    XCTFail("Unexpected response with error \(error)")
                }
            case .failed(let error):
                print(error)
            default:
                XCTFail("Could not get data back")
            }
        }
        wait(for: [completeInvoked], timeout: GraphQLModelBasedTests.networkTimeout)
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
