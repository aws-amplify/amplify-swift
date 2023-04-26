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

extension AppSyncListProviderTests {

    func testLoadedStateHasNextPageTrue() {
        let elements = [Post4(title: "title"), Post4(title: "title")]
        let provider = AppSyncListProvider(elements: elements, nextToken: "nextToken")
        guard case .loaded = provider.loadedState else {
            XCTFail("Should be loaded")
            return
        }
        XCTAssertTrue(provider.hasNextPage())
    }

    func testLoadedStateHasNextPageFalse() {
        let elements = [Post4(title: "title"), Post4(title: "title")]
        let provider = AppSyncListProvider(elements: elements, nextToken: nil)
        guard case .loaded = provider.loadedState else {
            XCTFail("Should be loaded")
            return
        }
        XCTAssertFalse(provider.hasNextPage())
    }
    
    func testNotLoadedStateHasNextPageFalse() {
        let modelMetadata = AppSyncListDecoder.Metadata(appSyncAssociatedIdentifiers: ["postId"],
                                                        appSyncAssociatedFields: ["post"],
                                                        apiName: "apiName")
        let provider = AppSyncListProvider<Comment4>(metadata: modelMetadata)
        guard case .notLoaded = provider.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        XCTAssertFalse(provider.hasNextPage())
    }

    func testLoadedStateGetNextPageSuccess() async throws {
        Amplify.Logging.logLevel = .verbose
        mockAPIPlugin.responders[.queryRequestResponse] = { _ in
                let nextPage = List(elements: [Comment4(content: "content"),
                                               Comment4(content: "content"),
                                               Comment4(content: "content")])
                let event: GraphQLOperation<List<Comment4>>.OperationResult = .success(.success(nextPage))
                return event
        } as QueryRequestResponder<List<Comment4>>
        let elements = [Comment4(content: "content")]
        let provider = AppSyncListProvider(elements: elements, nextToken: "nextToken")

        guard case .loaded = provider.loadedState else {
            XCTFail("Should be loaded")
            return
        }
        let list = try await provider.getNextPage()
        XCTAssertEqual(list.count, 3)
    }

    func testLoadedStateGetNextPageFailure_MissingNextToken() async {
        let elements = [Comment4(content: "content")]
        let provider = AppSyncListProvider(elements: elements, nextToken: nil)
        guard case .loaded = provider.loadedState else {
            XCTFail("Should be loaded")
            return
        }
        do {
            _ = try await provider.getNextPage()
            XCTFail("Should have failed")
        } catch CoreError.clientValidation {
            print("(Expected) error is CoreError.clientValidation")
        } catch {
            XCTFail("Unexpected error type \(error)")
        }
    }

    func testLoadedStateGetNextPageFailure_APIError() async {
        mockAPIPlugin.responders[.queryRequestResponse] = { _ in
                let event: GraphQLOperation<List<Comment4>>.OperationResult = .failure(APIError.unknown("", "", nil))
                return event
        } as QueryRequestResponder<List<Comment4>>
        let elements = [Comment4(content: "content")]
        let provider = AppSyncListProvider(elements: elements, nextToken: "nextToken")

        guard case .loaded = provider.loadedState else {
            XCTFail("Should be loaded")
            return
        }
        
        do {
            _ = try await provider.getNextPage()
            XCTFail("Should have failed")
        } catch CoreError.listOperation {
            print("(Expected) error is CoreError.listOperation")
        } catch {
            XCTFail("Unexpected error type \(error)")
        }
    }

    func testLoadedStateGetNextPageFailure_GraphQLErrorResponse() async {
        mockAPIPlugin.responders[.queryRequestResponse] = { _ in
                let event: GraphQLOperation<List<Comment4>>.OperationResult = .success(
                    .failure(GraphQLResponseError.error([GraphQLError]())))
                return event
        } as QueryRequestResponder<List<Comment4>>
        let elements = [Comment4(content: "content")]
        let provider = AppSyncListProvider(elements: elements, nextToken: "nextToken")
        guard case .loaded = provider.loadedState else {
            XCTFail("Should be loaded")
            return
        }
        
        do {
            _ = try await provider.getNextPage()
            XCTFail("Should have failed")
        } catch CoreError.listOperation(_, _, let underlyingError) {
            print("(Expected) error is CoreError.listOperation")
            guard (underlyingError as? GraphQLResponseError<List<Comment4>>) != nil else {
                XCTFail("Unexpected error \(String(describing: underlyingError))")
                return
            }
        } catch {
            XCTFail("Unexpected error type \(error)")
        }
    }
    
    func testNotLoadedStateGetNextPageFailure() async {
        let modelMetadata = AppSyncListDecoder.Metadata(appSyncAssociatedIdentifiers: ["postId"],
                                                        appSyncAssociatedFields: ["post"],
                                                        apiName: "apiName")
        let provider = AppSyncListProvider<Comment4>(metadata: modelMetadata)
        guard case .notLoaded = provider.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        do {
            _ = try await provider.getNextPage()
            XCTFail("Should have failed")
        } catch CoreError.clientValidation {
            print("(Expected) error is CoreError.clientValidation")
        } catch {
            XCTFail("Unexpected error type \(error)")
        }
    }
}
