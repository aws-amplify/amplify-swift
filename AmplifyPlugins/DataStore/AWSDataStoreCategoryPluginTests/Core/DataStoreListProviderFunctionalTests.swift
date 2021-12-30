//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSPluginsCore

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

class DataStoreListProviderFunctionalTests: BaseDataStoreTests {

    func testDataStoreListProviderWithAssociationDataShouldLoad() {
        let postId = preparePost4DataForTest()
        let provider = DataStoreListProvider<Comment4>(associatedId: postId, associatedField: "post")
        guard case .notLoaded = provider.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        let results = provider.load()
        guard case .loaded = provider.loadedState else {
            XCTFail("Should be loaded")
            return
        }
        guard case .success(let comments) = results else {
            XCTFail("Should be .success")
            return
        }
        XCTAssertEqual(comments.count, 2)
    }

    func testDataStoreListProviderWithAssociationDataShouldLoadWithCompletion() {
        let postId = preparePost4DataForTest()
        let provider = DataStoreListProvider<Comment4>(associatedId: postId, associatedField: "post")
        guard case .notLoaded = provider.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        let loadComplete = expectation(description: "Load completed")
        provider.load { result in
            switch result {
            case .success(let results):
                guard case .loaded = provider.loadedState else {
                    XCTFail("Should be loaded")
                    return
                }
                XCTAssertEqual(results.count, 2)
                loadComplete.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [loadComplete], timeout: 1)
    }

    // MARK: - Helpers

    func preparePost4DataForTest() -> Model.Identifier {
        let post = Post4(title: "title")
        populateData([post])
        populateData([
            Comment4(content: "Comment 1", post: post),
            Comment4(content: "Comment 1", post: post)
        ])
        return post.id
    }
}
