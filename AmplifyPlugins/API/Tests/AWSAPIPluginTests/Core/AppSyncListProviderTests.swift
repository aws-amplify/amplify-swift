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
@testable import AWSAPIPlugin

class AppSyncListProviderTests: XCTestCase {
    var mockAPIPlugin: MockAPICategoryPlugin!

    override func setUp() async throws {
        await Amplify.reset()
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
        let modelMetadata = AppSyncListDecoder.Metadata(appSyncAssociatedIdentifiers: ["postId"],
                                                        appSyncAssociatedFields: ["post"],
                                                        apiName: "apiName")
        let provider = AppSyncListProvider<Comment4>(metadata: modelMetadata)
        guard case .notLoaded(let associatedIdentifiers, let associatedFields) = provider.loadedState else {
            XCTFail("Should be in not loaded state")
            return
        }
        XCTAssertEqual(associatedIdentifiers, ["postId"])
        XCTAssertEqual(associatedFields, ["post"])
    }

    func testLoadedStateLoadSuccess() async throws {
        let elements = [Post4(title: "title"), Post4(title: "title")]
        let listProvider = AppSyncListProvider(elements: elements)
        let loadCompleted = asyncExpectation(description: "Load Completed")
        
        Task {
            let posts = try await listProvider.load()
            XCTAssertEqual(posts.count, 2)
            await loadCompleted.fulfill()
        }
        await waitForExpectations([loadCompleted], timeout: 1)
    }

    func testNotLoadedStateLoadSuccess() async throws {
        mockAPIPlugin.responders[.queryRequestResponse] = { _ in
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
            return event
        } as QueryRequestResponder<JSONValue>
        let modelMetadata = AppSyncListDecoder.Metadata(appSyncAssociatedIdentifiers: ["postId"],
                                                        appSyncAssociatedFields: ["post"],
                                                        apiName: "apiName")
        let provider = AppSyncListProvider<Comment4>(metadata: modelMetadata)
        guard case .notLoaded = provider.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        let loadCompleted = asyncExpectation(description: "Load Completed")
        
        Task {
            _ = try await provider.load()
            await loadCompleted.fulfill()
        }
        await waitForExpectations([loadCompleted], timeout: 1)
        
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
    
    func testNotLoadedStateSynchronousLoadFailure() async {
        mockAPIPlugin.responders[.queryRequestResponse] = { _ in
            let event: GraphQLOperation<JSONValue>.OperationResult = .failure(APIError.unknown("", "", nil))
            return event
        } as QueryRequestResponder<JSONValue>
        let modelMetadata = AppSyncListDecoder.Metadata(appSyncAssociatedIdentifiers: ["postId"],
                                                        appSyncAssociatedFields: ["post"],
                                                        apiName: "apiName")
        let provider = AppSyncListProvider<Comment4>(metadata: modelMetadata)
        guard case .notLoaded = provider.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        let loadCompleted = asyncExpectation(description: "Load Completed")
        Task {
            do {
                _ = try await provider.load()
                XCTFail("Should have failed")
            } catch let coreError as CoreError {
                guard case .listOperation(_, _, let underlyingError) = coreError,
                      (underlyingError as? APIError) != nil else {
                    XCTFail("Unexpected error \(coreError)")
                    return
                }
                guard case .notLoaded = provider.loadedState else {
                    XCTFail("Should not be loaded")
                    return
                }
                await loadCompleted.fulfill()
            }
        }
        await waitForExpectations([loadCompleted], timeout: 1)
    }
    
    func testNotLoadedStateLoadWithCompletionSuccess() async {
        mockAPIPlugin.responders[.queryRequestResponse] = { _ in
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
            return event
        } as QueryRequestResponder<JSONValue>
        let modelMetadata = AppSyncListDecoder.Metadata(appSyncAssociatedIdentifiers: ["postId"],
                                                        appSyncAssociatedFields: ["post"],
                                                        apiName: "apiName")
        let provider = AppSyncListProvider<Comment4>(metadata: modelMetadata)
        guard case .notLoaded = provider.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        let loadComplete = asyncExpectation(description: "Load completed")
        Task {
            _ = try await provider.load()
            await loadComplete.fulfill()
        }
        
        await waitForExpectations([loadComplete], timeout: 1)
        
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

    func testNotLoadedStateLoadWithCompletionFailure_APIError() async {
        mockAPIPlugin.responders[.queryRequestResponse] = { _ in
            let event: GraphQLOperation<JSONValue>.OperationResult = .failure(APIError.unknown("", "", nil))
            return event
        } as QueryRequestResponder<JSONValue>
        let modelMetadata = AppSyncListDecoder.Metadata(appSyncAssociatedIdentifiers: ["postId"],
                                                        appSyncAssociatedFields: ["post"],
                                                        apiName: "apiName")
        let provider = AppSyncListProvider<Comment4>(metadata: modelMetadata)
        guard case .notLoaded = provider.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        let loadComplete = asyncExpectation(description: "Load completed")
        Task {
            do {
                _ = try await provider.load()
                XCTFail("Should have failed")
            } catch let error as CoreError {
                guard case .listOperation(_, _, let underlyingError) = error,
                      (underlyingError as? APIError) != nil else {
                    XCTFail("Unexpected error \(error)")
                    return
                }
                await loadComplete.fulfill()
            }
        }
        await waitForExpectations([loadComplete], timeout: 1)
        guard case .notLoaded = provider.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
    }

    func testNotLoadedStateLoadWithCompletionFailure_GraphQLErrorResponse() async {
        mockAPIPlugin.responders[.queryRequestResponse] = { _ in
            let event: GraphQLOperation<JSONValue>.OperationResult = .success(
                .failure(GraphQLResponseError.error([GraphQLError]())))
            return event
        } as QueryRequestResponder<JSONValue>
        let modelMetadata = AppSyncListDecoder.Metadata(appSyncAssociatedIdentifiers: ["postId"],
                                                 appSyncAssociatedFields: ["post"],
                                                 apiName: "apiName")
        let provider = AppSyncListProvider<Comment4>(metadata: modelMetadata)
        guard case .notLoaded = provider.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        let loadComplete = asyncExpectation(description: "Load completed")
        Task {
            
            do {
                _ = try await provider.load()
                XCTFail("Should have failed")
            } catch let error as CoreError {
                guard case .listOperation(_, _, let underlyingError) = error,
                      (underlyingError as? GraphQLResponseError<JSONValue>) != nil else {
                    XCTFail("Unexpected error \(error)")
                    return
                }
                await loadComplete.fulfill()
            }
            
        }
        await waitForExpectations([loadComplete], timeout: 1)
        guard case .notLoaded = provider.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
    }
    
    func testNotLoadedStateLoadWithCompletionFailure_AWSAppSyncListResponseFailure() async {
        mockAPIPlugin.responders[.queryRequestResponse] = { _ in
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
            return event
        } as QueryRequestResponder<JSONValue>
        let modelMetadata = AppSyncListDecoder.Metadata(appSyncAssociatedIdentifiers: ["postId"],
                                                        appSyncAssociatedFields: ["post"],
                                                        apiName: "apiName")
        let provider = AppSyncListProvider<Comment4>(metadata: modelMetadata)
        guard case .notLoaded = provider.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        let loadComplete = asyncExpectation(description: "Load completed")
        Task {
            do {
                _ = try await provider.load()
                XCTFail("Should have failed")
            } catch let error as CoreError {
                guard case .listOperation = error else {
                    XCTFail("Unexpected error \(error)")
                    return
                }
                await loadComplete.fulfill()
                
            }
        }
        await waitForExpectations([loadComplete], timeout: 1)
        guard case .notLoaded = provider.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
    }
}
