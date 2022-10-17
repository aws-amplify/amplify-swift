//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSAPIPlugin
@testable import Amplify
@testable import APIHostApp
@testable import AWSPluginsCore

class GraphQLLazyLoadBaseTest: XCTestCase {
    static let amplifyConfiguration = "testconfiguration/GraphQLLazyLoadTests-amplifyconfiguration"

    override func setUp() async throws {
        await Amplify.reset()
        Amplify.Logging.logLevel = .verbose
        let plugin = AWSAPIPlugin(modelRegistration: AmplifyModels())
        
        do {
            try Amplify.add(plugin: plugin)
            
            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(
                forResource: GraphQLLazyLoadBaseTest.amplifyConfiguration)
            try Amplify.configure(amplifyConfig)
            
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    func testExample() async throws {
        let post = Post4V2(title: "title")
        let comment = Comment4V2(content: "content", post: post)
        
        // LazyModel will perform a query for post by the identifier metadata post.id
        let response = try await Amplify.API.query(request: .get(Post4V2.self, byId: post.id))
        
        switch response {
        case .success(let post):
            print("\(post)")
        case .failure(let error):
            XCTFail("Failed with error \(error)")
        }
    }
    
    func testGetPostWithCompositeKey() async throws {
        let post = PostWithCompositeKey(id: UUID().uuidString,
                                        title: UUID().uuidString)
        let comment = CommentWithCompositeKey(content: "content", post: post)
        
        // Save the post
        // save the comment with the post
        // query for the post with lazy load enabled, and lazy load the comment.
        
        // LazyModel will perform a query for post by the identifier metadata post.id and post.title
//        let response = try await Amplify.API.query(
//            request: GraphQLLazyLoadBaseTest.get(PostWithCompositeKey.self,
//                                                 byIdentifiers: ["id": post.id,
//                                                                 "title": post.title]))
//        switch response {
//        case .success(let post):
//            print("\(post)")
//        case .failure(let error):
//            XCTFail("Failed with error \(error)")
//        }
    }
}
