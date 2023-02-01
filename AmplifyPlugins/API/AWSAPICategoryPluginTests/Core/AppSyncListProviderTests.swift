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
@testable import AWSAPICategoryPlugin

// swiftlint:disable:next type_body_length
class AppSyncListProviderTests: XCTestCase {
    var mockAPIPlugin: MockAPICategoryPlugin!

    override func setUp() {
        Amplify.reset()
        ModelRegistry.register(modelType: Post4.self)
        ModelRegistry.register(modelType: Comment4.self)
        ModelListDecoderRegistry.registerDecoder(AppSyncListDecoder.self)
        do {
            let configWithAPI = try setUpAPICategory()
            try Amplify.configure(configWithAPI)
        } catch {
            XCTFail(String(describing: "Unable to setup API category for unit tests"))
        }
    }

    private func setUpAPICategory() throws -> AmplifyConfiguration {
        mockAPIPlugin = MockAPICategoryPlugin()
        try Amplify.add(plugin: mockAPIPlugin)

        let apiConfig = APICategoryConfiguration(plugins: [
            "MockAPICategoryPlugin": true
        ])
        let amplifyConfig = AmplifyConfiguration(api: apiConfig)
        return amplifyConfig
    }

    func testInitWithAppSyncListPayloadShouldBeLoadedState() throws {
        let json: JSONValue = [
            "items": [
                [
                    "id": "1",
                    "title": JSONValue.init(stringLiteral: "title")
                ], [
                    "id": "2",
                    "title": JSONValue.init(stringLiteral: "title")
                ]
            ],
            "nextToken": "nextToken"
        ]
        let variables: [String: JSONValue] = [
            "filter": [
                "postID": [
                    "eq": "postId123"
                ]
            ],
            "limit": 500
        ]
        let appSyncPayload = AppSyncListPayload(graphQLData: json, apiName: "apiName", variables: variables)
        let provider = try AppSyncListProvider<Post4>(payload: appSyncPayload)
        guard case .loaded(let elements, let nextToken, let filter) = provider.loadedState else {
            XCTFail("Should be in loaded state")
            return
        }
        XCTAssertEqual(elements.count, 2)
        XCTAssertEqual(nextToken, "nextToken")
        XCTAssertEqual(provider.apiName, "apiName")
        XCTAssertEqual(provider.limit, 500)
        XCTAssertNotNil(filter)
    }

    func testInitWithInvalidPayloadShouldThrow() {
        let json: JSONValue = [
            "items": [
                [
                    "id": "1",
                    "invalidKeyForPost4": JSONValue.init(stringLiteral: "title")
                ]
            ],
            "nextToken": "nextToken"
        ]
        let appSyncPayload = AppSyncListPayload(graphQLData: json, apiName: nil, variables: nil)
        do {
            _ = try AppSyncListProvider<Post4>(payload: appSyncPayload)
        } catch _ as DecodingError {

        } catch {
            XCTFail("Should be caught as decoding error")
        }
    }

    func testInitWithModelMetadataShouldBeNotLoadedState() throws {
        let modelMetadata = AppSyncModelMetadata(appSyncAssociatedId: "postId",
                                                 appSyncAssociatedField: "post",
                                                 apiName: "apiName")
        let provider = AppSyncListProvider<Comment4>(metadata: modelMetadata)
        guard case .notLoaded(let associatedId, let associatedField) = provider.loadedState else {
            XCTFail("Should be in not loaded state")
            return
        }
        XCTAssertEqual(associatedId, "postId")
        XCTAssertEqual(associatedField, "post")
    }

    func testLoadedStateSynchronousLoadSuccess() {
        let elements = [Post4(title: "title"), Post4(title: "title")]
        let listProvider = AppSyncListProvider(elements: elements)
        let results = listProvider.load()
        guard case .success(let posts) = results else {
            XCTFail("Should be .success")
            return
        }
        XCTAssertEqual(posts.count, 2)
    }

    func testNotLoadedStateSyncrhonousLoadSuccess() {
        mockAPIPlugin.responders[.queryRequestListener] =
            QueryRequestListenerResponder<JSONValue> { _, listener in
                let json: JSONValue = [
                    "items": [
                        [
                            "id": "1",
                            "content": JSONValue.init(stringLiteral: "content")
                        ], [
                            "id": "2",
                            "content": JSONValue.init(stringLiteral: "content")
                        ]
                    ],
                    "nextToken": "nextToken"
                ]
                let event: GraphQLOperation<JSONValue>.OperationResult = .success(.success(json))
                listener?(event)
                return nil
        }
        let modelMetadata = AppSyncModelMetadata(appSyncAssociatedId: "postId",
                                                 appSyncAssociatedField: "post",
                                                 apiName: "apiName")
        let provider = AppSyncListProvider<Comment4>(metadata: modelMetadata)
        guard case .notLoaded = provider.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        let result = provider.load()

        guard case .success = result else {
            XCTFail("Should have been success")
            return
        }
        guard case .loaded(let elements, let nextToken, let filterOptional) = provider.loadedState else {
            XCTFail("Should be loaded")
            return
        }
        XCTAssertEqual(elements.count, 2)
        XCTAssertEqual(nextToken, "nextToken")
        guard let filter = filterOptional,
              let postFilter = filter["postID"] as? [String: String],
              let postId = postFilter["eq"] else {
            XCTFail("Could not retrieve filter values")
            return
        }
        XCTAssertEqual(postId, "postId")
    }

    func testNotLoadedStateSynchronousLoadFailure() {
        mockAPIPlugin.responders[.queryRequestListener] =
            QueryRequestListenerResponder<JSONValue> { _, listener in
                let event: GraphQLOperation<JSONValue>.OperationResult = .failure(APIError.unknown("", "", nil))
                listener?(event)
                return nil
        }
        let modelMetadata = AppSyncModelMetadata(appSyncAssociatedId: "postId",
                                                 appSyncAssociatedField: "post",
                                                 apiName: "apiName")
        let provider = AppSyncListProvider<Comment4>(metadata: modelMetadata)
        guard case .notLoaded = provider.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        let result = provider.load()
        switch result {
        case .success:
            XCTFail("Should have failed")
        case .failure(let coreError):
            guard case .listOperation(_, _, let underlyingError) = coreError,
                  (underlyingError as? APIError) != nil else {
                XCTFail("Unexpected error \(coreError)")
                return
            }
        }
        guard case .notLoaded = provider.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
    }

    func testLoadedStateLoadWithCompletionSuccess() {
        let elements = [Post4(title: "title"), Post4(title: "title")]
        let provider = AppSyncListProvider(elements: elements)
        guard case .loaded = provider.loadedState else {
            XCTFail("Should be loaded")
            return
        }
        let loadComplete = expectation(description: "Load completed")
        provider.load { result in
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

    func testNotLoadedStateLoadWithCompletionSuccess() {
        mockAPIPlugin.responders[.queryRequestListener] =
            QueryRequestListenerResponder<JSONValue> { _, listener in
                let json: JSONValue = [
                    "items": [
                        [
                            "id": "1",
                            "content": JSONValue.init(stringLiteral: "content")
                        ], [
                            "id": "2",
                            "content": JSONValue.init(stringLiteral: "content")
                        ]
                    ],
                    "nextToken": "nextToken"
                ]
                let event: GraphQLOperation<JSONValue>.OperationResult = .success(.success(json))
                listener?(event)
                return nil
        }
        let modelMetadata = AppSyncModelMetadata(appSyncAssociatedId: "postId",
                                                 appSyncAssociatedField: "post",
                                                 apiName: "apiName")
        let provider = AppSyncListProvider<Comment4>(metadata: modelMetadata)
        guard case .notLoaded = provider.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        let loadComplete = expectation(description: "Load completed")
        provider.load { result in
            switch result {
            case .success:
                loadComplete.fulfill()
            case .failure(let error):
                XCTFail("\(error)")

            }
        }
        wait(for: [loadComplete], timeout: 1)
        guard case .loaded(let elements, let nextToken, let filterOptional) = provider.loadedState else {
            XCTFail("Should be loaded")
            return
        }
        XCTAssertEqual(elements.count, 2)
        XCTAssertEqual(nextToken, "nextToken")
        guard let filter = filterOptional,
              let postFilter = filter["postID"] as? [String: String],
              let postId = postFilter["eq"] else {
            XCTFail("Could not retrieve filter values")
            return
        }
        XCTAssertEqual(postId, "postId")
    }

    func testNotLoadedStateLoadWithCompletionFailure_APIError() {
        mockAPIPlugin.responders[.queryRequestListener] =
            QueryRequestListenerResponder<JSONValue> { _, listener in
                let event: GraphQLOperation<JSONValue>.OperationResult = .failure(APIError.unknown("", "", nil))
                listener?(event)
                return nil
        }
        let modelMetadata = AppSyncModelMetadata(appSyncAssociatedId: "postId",
                                                 appSyncAssociatedField: "post",
                                                 apiName: "apiName")
        let provider = AppSyncListProvider<Comment4>(metadata: modelMetadata)
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
                guard case .listOperation(_, _, let underlyingError) = error,
                      (underlyingError as? APIError) != nil else {
                    XCTFail("Unexpected error \(error)")
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

    func testNotLoadedStateLoadWithCompletionFailure_GraphQLErrorResponse() {
        mockAPIPlugin.responders[.queryRequestListener] =
            QueryRequestListenerResponder<JSONValue> { _, listener in
                let event: GraphQLOperation<JSONValue>.OperationResult = .success(
                    .failure(GraphQLResponseError.error([GraphQLError]())))
                listener?(event)
                return nil
        }
        let modelMetadata = AppSyncModelMetadata(appSyncAssociatedId: "postId",
                                                 appSyncAssociatedField: "post",
                                                 apiName: "apiName")
        let provider = AppSyncListProvider<Comment4>(metadata: modelMetadata)
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
                guard case .listOperation(_, _, let underlyingError) = error,
                      (underlyingError as? GraphQLResponseError<JSONValue>) != nil else {
                    XCTFail("Unexpected error \(error)")
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

    func testNotLoadedStateLoadWithCompletionFailure_AWSAppSyncListResponseFailure() {
        mockAPIPlugin.responders[.queryRequestListener] =
            QueryRequestListenerResponder<JSONValue> { _, listener in
                let json: JSONValue = [
                    "items": [
                        [
                            "id": "1",
                            "invalidKey": JSONValue.init(stringLiteral: "content")
                        ], [
                            "id": "2",
                            "invalidKey": JSONValue.init(stringLiteral: "content")
                        ]
                    ],
                    "nextToken": "nextToken"
                ]
                let event: GraphQLOperation<JSONValue>.OperationResult = .success(.success(json))
                listener?(event)
                return nil
        }
        let modelMetadata = AppSyncModelMetadata(appSyncAssociatedId: "postId",
                                                 appSyncAssociatedField: "post",
                                                 apiName: "apiName")
        let provider = AppSyncListProvider<Comment4>(metadata: modelMetadata)
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
                    XCTFail("Unexpected error \(error)")
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
}
