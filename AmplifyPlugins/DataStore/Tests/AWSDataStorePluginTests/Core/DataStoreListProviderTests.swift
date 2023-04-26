//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

class DataStoreListProviderTests: XCTestCase {

    var mockDataStorePlugin: MockDataStoreCategoryPlugin!

    override func setUp() async throws {
        await Amplify.reset()
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
        let provider = DataStoreListProvider<Post4>(metadata: .init(dataStoreAssociatedIdentifiers: ["id"],
                                                                    dataStoreAssociatedFields: ["field"]))
        guard case .notLoaded = provider.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
    }

    func testNotLoadedStateLoadSuccess() async throws {
        mockDataStorePlugin.responders[.queryModelsListener] = { _, _, _, _ in
                return .success([Comment4(content: "content"),
                                 Comment4(content: "content")])
            } as QueryModelsResponder<Comment4>

        let provider = DataStoreListProvider<Comment4>(metadata: .init(dataStoreAssociatedIdentifiers: ["postId"],
                                                                    dataStoreAssociatedFields: ["post"]))
        guard case .notLoaded = provider.loadedState else {
            XCTFail("Should not be loaded")
            return
        }

        let comments = try await provider.load()
        XCTAssertEqual(comments.count, 2)
        guard case .loaded = provider.loadedState else {
            XCTFail("Should be loaded")
            return
        }
    }

    func testLoadedStateLoadSuccess() async throws {
        let elements = [Post4(title: "title"), Post4(title: "title")]
        let listProvider = DataStoreListProvider<Post4>(elements)
        guard case .loaded = listProvider.loadedState else {
            XCTFail("Should be loaded")
            return
        }
        
        let results = try await listProvider.load()
        XCTAssertEqual(results.count, 2)
    }

    func testNotLoadedStateLoadFailure() async throws {
        mockDataStorePlugin.responders[.queryModelsListener] = { _, _, _, _ in
            return .failure(DataStoreError.internalOperation("", "", nil))
        } as QueryModelsResponder<Comment4>
        
        let provider = DataStoreListProvider<Comment4>(metadata: .init(dataStoreAssociatedIdentifiers: ["postId"],
                                                                    dataStoreAssociatedFields: ["post"]))
        guard case .notLoaded = provider.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        do {
            _ = try await provider.load()
            XCTFail("Should have failed with error")
        } catch CoreError.listOperation {
            print("(Expected) error is CoreError.listOperation")
        } catch {
            throw error
        }
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

    func testGetNextPageAlwaysReturnsFailure() async throws {
        let elements = [Post4(title: "title"), Post4(title: "title")]
        let provider = DataStoreListProvider<Post4>(elements)
        do {
            _ = try await provider.getNextPage()
            XCTFail("Should have failed with error")
        } catch CoreError.clientValidation {
            print("(Expected) error is CoreError.clientValidation")
        } catch {
            throw error
        }
    }
}
