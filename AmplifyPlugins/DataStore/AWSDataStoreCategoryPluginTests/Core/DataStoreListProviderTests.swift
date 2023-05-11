//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

class DataStoreListProviderTests: XCTestCase {

    var mockDataStorePlugin: MockDataStoreCategoryPlugin!

    override func setUp() {
        Amplify.reset()
        ModelRegistry.register(modelType: Post4.self)
        ModelRegistry.register(modelType: Comment4.self)
        ModelListDecoderRegistry.registerDecoder(DataStoreListDecoder.self)

        do {
            let configWithDataStore = try setUpDataStore()
            try Amplify.configure(configWithDataStore)
        } catch {
            XCTFail("Unable to set up DataStore for unit tests")
        }
    }

    private func setUpDataStore() throws -> AmplifyConfiguration {
        mockDataStorePlugin = MockDataStoreCategoryPlugin()
        try Amplify.add(plugin: mockDataStorePlugin)
        let dataStoreConfig = DataStoreCategoryConfiguration(plugins: [
            "MockDataStoreCategoryPlugin": true
        ])
        let amplifyConfig = AmplifyConfiguration(dataStore: dataStoreConfig)
        return amplifyConfig
    }

    func testInitWithElementsShouldBeLoadedState() {
        let elements = [Post4(title: "title"), Post4(title: "title")]
        let provider = DataStoreListProvider<Post4>(elements)
        guard case .loaded = provider.loadedState else {
            XCTFail("Should be loaded")
            return
        }
    }

    func testInitWithAssociationDataShouldBeInNotLoadedState() {
        let provider = DataStoreListProvider<Post4>(associatedIdentifiers: ["id"], associatedField: "field")
        guard case .notLoaded = provider.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
    }

    func testLoadedStateSynchronousLoadSuccess() {
        let elements = [Post4(title: "title"), Post4(title: "title")]
        let provider = DataStoreListProvider<Post4>(elements)
        guard case .loaded = provider.loadedState else {
            XCTFail("Should be loaded")
            return
        }
        let results = provider.load()
        guard case .success(let posts) = results else {
            XCTFail("Should be .success")
            return
        }
        XCTAssertEqual(posts.count, 2)
    }

    func testNotLoadedStateSynchronousLoadSuccess() {
        mockDataStorePlugin.responders[.queryModelsListener] =
            QueryModelsResponder<Comment4> { _, _, _, _ in
                return .success([Comment4(content: "content"),
                                 Comment4(content: "content")])
            }

        let provider = DataStoreListProvider<Comment4>(associatedIdentifiers: ["postId"], associatedField: "post")
        guard case .notLoaded = provider.loadedState else {
            XCTFail("Should not be loaded")
            return
        }

        let results = provider.load()
        guard case .success(let comments) = results else {
            XCTFail("Should be .success")
            return
        }
        XCTAssertEqual(comments.count, 2)
        guard case .loaded = provider.loadedState else {
            XCTFail("Should be loaded")
            return
        }
    }

    func testNotLoadedStateSynchronousLoadAssert() throws {
        mockDataStorePlugin.responders[.queryModelsListener] =
            QueryModelsResponder<Comment4> { _, _, _, _ in
                return .failure(DataStoreError.internalOperation("", "", nil))
            }

        let provider = DataStoreListProvider<Comment4>(associatedIdentifiers: ["postId"], associatedField: "post")
        guard case .notLoaded = provider.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        try XCTAssertThrowFatalError {
            _ = provider.load()
        }
    }

    func testLoadedStateLoadWithCompletionSuccess() {
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

    func testNotLoadedStateLoadWithCompletionFailure() {
        mockDataStorePlugin.responders[.queryModelsListener] =
            QueryModelsResponder<Comment4> { _, _, _, _ in
                return .failure(DataStoreError.internalOperation("", "", nil))
            }

        let provider = DataStoreListProvider<Comment4>(associatedIdentifiers: ["postId"], associatedField: "post")
        guard case .notLoaded = provider.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        let loadComplete = expectation(description: "Load completed")
        provider.load { result in
            switch result {
            case .success:
                XCTFail("Should have failed")
            case .failure(let error):
                guard case .listOperation = error else {
                    XCTFail("Expected list operation error")
                    return
                }
                loadComplete.fulfill()
            }
        }
        wait(for: [loadComplete], timeout: 1)
        guard case .notLoaded = provider.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
    }

    func testHasNextPageAlwaysReturnsFalse() {
        let elements = [Post4(title: "title"), Post4(title: "title")]
        let provider = DataStoreListProvider<Post4>(elements)
        XCTAssertFalse(provider.hasNextPage())
    }

    func testGetNextPageAlwaysReturnsFailure() {
        let elements = [Post4(title: "title"), Post4(title: "title")]
        let provider = DataStoreListProvider<Post4>(elements)
        let getNextPageComplete = expectation(description: "getNextPage completed")
        provider.getNextPage { result in
            switch result {
            case .success:
                XCTFail("Should have failed")
            case .failure(let coreError):
                guard case .clientValidation = coreError else {
                    XCTFail("Should be clientValidation error")
                    return
                }
                getNextPageComplete.fulfill()
            }
        }
        wait(for: [getNextPageComplete], timeout: 1)
    }
}
