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
 ```
 # 6 - Blog Post Comment
 type Blog6 @model {
   id: ID!
   name: String!
   posts: [Post6] @connection(keyName: "byBlog", fields: ["id"])
 }

 type Post6 @model @key(name: "byBlog", fields: ["blogID"]) {
   id: ID!
   title: String!
   blogID: ID!
   blog: Blog6 @connection(fields: ["blogID"])
   comments: [Comment6] @connection(keyName: "byPost", fields: ["id"])
 }

 type Comment6 @model @key(name: "byPost", fields: ["postID", "content"]) {
   id: ID!
   postID: ID!
   post: Post6 @connection(fields: ["postID"])
   content: String!
 }
 ```
 */
class GraphQLConnectionScenario6Tests: XCTestCase {

    override func setUp() {
        do {
            Amplify.Logging.logLevel = .verbose
            try Amplify.add(plugin: AWSAPIPlugin())

            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(
                forResource: GraphQLModelBasedTests.amplifyConfiguration)
            try Amplify.configure(amplifyConfig)

            ModelRegistry.register(modelType: Blog6.self)
            ModelRegistry.register(modelType: Post6.self)
            ModelRegistry.register(modelType: Comment6.self)

        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func tearDown() {
        Amplify.reset()
    }

    func createBlog(id: String = UUID().uuidString, name: String) -> Blog6? {
        let blog = Blog6(id: id, name: name)
        var result: Blog6?
        let requestInvokedSuccessfully = expectation(description: "request completed")
        Amplify.API.mutate(request: .create(blog)) { event in
            switch event {
            case .success(let data):
                switch data {
                case .success(let post):
                    result = post
                default:
                    XCTFail("Could not get data back")
                }
                requestInvokedSuccessfully.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [requestInvokedSuccessfully], timeout: TestCommonConstants.networkTimeout)
        return result
    }

    func createPost(id: String = UUID().uuidString, title: String, blog: Blog6) -> Post6? {
        let post = Post6(id: id, title: title, blog: blog)
        var result: Post6?
        let requestInvokedSuccessfully = expectation(description: "request completed")
        Amplify.API.mutate(request: .create(post)) { event in
            switch event {
            case .success(let data):
                switch data {
                case .success(let post):
                    result = post
                default:
                    XCTFail("Could not get data back")
                }
                requestInvokedSuccessfully.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [requestInvokedSuccessfully], timeout: TestCommonConstants.networkTimeout)
        return result
    }

    func createComment(id: String = UUID().uuidString, post: Post6, content: String) -> Comment6? {
        let comment = Comment6(id: id, post: post, content: content)
        var result: Comment6?
        let requestInvokedSuccessfully = expectation(description: "request completed")
        Amplify.API.mutate(request: .create(comment)) { event in
            switch event {
            case .success(let data):
                switch data {
                case .success(let comment):
                    result = comment
                default:
                    XCTFail("Could not get data back")
                }
                requestInvokedSuccessfully.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [requestInvokedSuccessfully], timeout: TestCommonConstants.networkTimeout)
        return result
    }
}
