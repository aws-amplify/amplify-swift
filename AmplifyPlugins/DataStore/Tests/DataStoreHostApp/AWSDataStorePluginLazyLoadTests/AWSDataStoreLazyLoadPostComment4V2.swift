//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Combine
import XCTest

@testable import Amplify

class AWSDataStoreLazyLoadPostComment4V2: AWSDataStoreLazyLoadBaseTest {

    func testExample() async throws {
        await setup(withModels: PostComment4V2Models())
        let post = Post4V2(title: "title")
        let comment = Comment4V2(content: "content", post: post)
        
        let commentSynced = asyncExpectation(description: "DataStore start success")
        let mutationEvents = Amplify.DataStore.observe(Comment4V2.self)
        Task {
            do {
                for try await mutationEvent in mutationEvents {
                    if mutationEvent.version == 1 && mutationEvent.modelId == comment.id {
                        await commentSynced.fulfill()
                    }
                }
            } catch {
                XCTFail("Failed with error \(error)")
            }
        }
        
        try await Amplify.DataStore.save(post)
        try await Amplify.DataStore.save(comment)
        
        await waitForExpectations([commentSynced], timeout: 10)
    }
}


extension AWSDataStoreLazyLoadPostComment4V2 {
    struct PostComment4V2Models: AmplifyModelRegistration {
        public let version: String = "version"
        func registerModels(registry: ModelRegistry.Type) {
            ModelRegistry.register(modelType: Post4V2.self)
            ModelRegistry.register(modelType: Comment4V2.self)
        }
    }
}
