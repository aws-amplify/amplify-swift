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
@testable import AWSDataStoreCategoryPlugin

class DataStoreListProviderTests: BaseDataStoreTests {

    func testDataStoreListProviderWithElementsShouldLoad() {
        let elements = [Post4(title: "title"), Post4(title: "title")]
        let listProvider = DataStoreListProvider<Post4>(elements)
        guard case .loaded = listProvider.loadedState else {
            XCTFail("Should be loaded")
            return
        }
        let results = listProvider.load()
        guard case .success(let posts) = results else {
            XCTFail("Should be .success")
            return
        }
        XCTAssertEqual(posts.count, 2)
    }

    func testDataStoreListProviderWithElementsShouldLoadWithCompletion() {
        let elements = [Post4(title: "title"), Post4(title: "title")]
        let listProvider = DataStoreListProvider<Post4>(elements)
        let loadComplete = expectation(description: "Load completed")
        guard case .loaded = listProvider.loadedState else {
            XCTFail("Should be loaded")
            return
        }
        listProvider.load { result in
            switch result {
            case .success(let results):
                XCTAssertEqual(results.count, 2)
                loadComplete.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [loadComplete], timeout: 1)
    }

    func testDataStoreListProviderWithAssociationDataShouldLoad() {
        let postId = preparePost4DataForTest()
        guard let postField = Comment4.schema.field(withName: "post") else {
            XCTFail("Could not set up associated field")
            return
        }

        let listProvider = DataStoreListProvider<Comment4>(associatedId: postId, associatedField: postField)
        guard case .notLoaded = listProvider.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        let results = listProvider.load()
        guard case .loaded = listProvider.loadedState else {
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
        guard let postField = Comment4.schema.field(withName: "post") else {
            XCTFail("Could not set up associated field")
            return
        }

        let listProvider = DataStoreListProvider<Comment4>(associatedId: postId, associatedField: postField)
        guard case .notLoaded = listProvider.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        let loadComplete = expectation(description: "Load completed")
        listProvider.load { result in
            switch result {
            case .success(let results):
                guard case .loaded = listProvider.loadedState else {
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
