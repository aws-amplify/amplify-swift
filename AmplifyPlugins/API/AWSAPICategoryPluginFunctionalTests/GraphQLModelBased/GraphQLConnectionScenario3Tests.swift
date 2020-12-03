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
}
