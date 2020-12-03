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

 # Create a join model and disable queries as you don't need them
 # and can query through Post5.editors and User5.posts
 type PostEditor5
   @model(queries: null)
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
 See https://docs.amplify.aws/cli/graphql-transformer/connection for more details
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
}
