//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon

final class LazyReferenceTests: XCTestCase {
    
    override func setUp() {
        ModelRegistry.register(modelType: LazyParentPost4V2.self)
        ModelRegistry.register(modelType: LazyChildComment4V2.self)
    }
    
    class MockModelProvider<ModelType: Model>: ModelProvider {
        enum LoadedState {
            case notLoaded(identifiers: [LazyReferenceIdentifier]?)
            case loaded(model: ModelType?)
        }
        
        var loadedState: LoadedState
        
        init(loadedState: LoadedState) {
            self.loadedState = loadedState
        }
        
        func load() async throws -> Element? {
            return nil
        }
        
        func getState() -> ModelProviderState<ModelType> {
            switch loadedState {
            case .notLoaded(let identifiers):
                return .notLoaded(identifiers: identifiers)
            case .loaded(let model):
                return .loaded(model: model)
            }
        }
        
        func encode(to encoder: Encoder) throws {
            switch loadedState {
            case .notLoaded(let identifiers):
                var container = encoder.singleValueContainer()
                try container.encode(identifiers)
            case .loaded(let model):
                try model.encode(to: encoder)
            }
        }
    }
    
    func testEncodeDecodeLoaded() throws {
        let post = LazyParentPost4V2(id: "postId", title: "t")
        let comment = LazyChildComment4V2(id: "commentId", content: "c", post: post)
        let json = try comment.toJSON()
        XCTAssertEqual(json, "{\"post\":{\"id\":\"postId\",\"title\":\"t\",\"comments\":[]},\"id\":\"commentId\",\"content\":\"c\",\"updatedAt\":null,\"createdAt\":null}")
        
        guard let decodedComment = try ModelRegistry.decode(modelName: LazyChildComment4V2.modelName, from: json) as? LazyChildComment4V2 else {
            XCTFail("Could not decode to comment from json")
            return
        }
        switch decodedComment._post.loadedState {
        case .notLoaded:
            XCTFail("Should be loaded")
        case .loaded(let element):
            guard let loadedPost = element else {
                XCTFail("Missing post")
                return
            }
            XCTAssertEqual(loadedPost.id, post.id)
            XCTAssertEqual(loadedPost.title, post.title)
        }
    }
    
    func testEncodeNotLoaded() async throws {
        var comment = LazyChildComment4V2(id: "commentId", content: "content")
        let modelProvider = MockModelProvider<LazyParentPost4V2>(loadedState:
                .notLoaded(identifiers: [.init(name: "id", value: "postId")])).eraseToAnyModelProvider()
        
        comment._post = LazyReference(modelProvider: modelProvider)
        let json = try comment.toJSON()
        XCTAssertEqual(json, "{\"post\":[{\"name\":\"id\",\"value\":\"postId\"}],\"id\":\"commentId\",\"content\":\"content\",\"updatedAt\":null,\"createdAt\":null}")
    }
}
