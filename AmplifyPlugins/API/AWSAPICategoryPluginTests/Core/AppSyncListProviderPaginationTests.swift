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
        let modelMetadata = AppSyncModelMetadata(appSyncAssociatedId: "postId",
                                                 appSyncAssociatedField: "post",
                                                 apiName: "apiName")
        let provider = AppSyncListProvider<Comment4>(metadata: modelMetadata)
        guard case .notLoaded = provider.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        XCTAssertFalse(provider.hasNextPage())
    }

    func testLoadedStateGetNextPageSuccess() {
        mockAPIPlugin.responders[.queryRequestListener] =
            QueryRequestListenerResponder<List<Comment4>> { _, listener in
                let nextPage = List(elements: [Comment4(content: "content"),
                                               Comment4(content: "content"),
                                               Comment4(content: "content")])
                let event: GraphQLOperation<List<Comment4>>.OperationResult = .success(.success(nextPage))
                listener?(event)
                return nil
        }
        let elements = [Comment4(content: "content")]
        let provider = AppSyncListProvider(elements: elements, nextToken: "nextToken")

        guard case .loaded = provider.loadedState else {
            XCTFail("Should be loaded")
            return
        }
        let getNextPageComplete = expectation(description: "get next page completed")
        provider.getNextPage { result in
            switch result {
            case .success(let list):
                XCTAssertEqual(list.count, 3)
                getNextPageComplete.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [getNextPageComplete], timeout: 1)
    }

    func testLoadedStateGetNextPageFailure_MissingNextToken() {
        let elements = [Comment4(content: "content")]
        let provider = AppSyncListProvider(elements: elements, nextToken: nil)
        guard case .loaded = provider.loadedState else {
            XCTFail("Should be loaded")
            return
        }
        let getNextPageComplete = expectation(description: "get next page completed")
        provider.getNextPage { result in
            switch result {
            case .success:
                XCTFail("Should have failed")
            case .failure(let error):
                guard case .clientValidation = error else {
                    XCTFail("Unexpected error type \(error)")
                    return
                }
                getNextPageComplete.fulfill()
            }
        }
        wait(for: [getNextPageComplete], timeout: 1)
    }

    func testLoadedStateGetNextPageFailure_APIError() {
        mockAPIPlugin.responders[.queryRequestListener] =
            QueryRequestListenerResponder<List<Comment4>> { _, listener in
                let event: GraphQLOperation<List<Comment4>>.OperationResult = .failure(APIError.unknown("", "", nil))
                listener?(event)
                return nil
        }
        let elements = [Comment4(content: "content")]
        let provider = AppSyncListProvider(elements: elements, nextToken: "nextToken")

        guard case .loaded = provider.loadedState else {
            XCTFail("Should be loaded")
            return
        }
        let getNextPageComplete = expectation(description: "get next page completed")
        provider.getNextPage { result in
            switch result {
            case .success:
                XCTFail("Should have failed")
            case .failure(let error):
                guard case .listOperation = error else {
                    XCTFail("Unexpected error type \(error)")
                    return
                }
                getNextPageComplete.fulfill()
            }
        }
        wait(for: [getNextPageComplete], timeout: 1)
    }

    func testLoadedStateGetNextPageFailure_GraphQLErrorResponse() {
        mockAPIPlugin.responders[.queryRequestListener] =
            QueryRequestListenerResponder<List<Comment4>> { _, listener in
                let event: GraphQLOperation<List<Comment4>>.OperationResult = .success(
                    .failure(GraphQLResponseError.error([GraphQLError]())))
                listener?(event)
                return nil
        }
        let elements = [Comment4(content: "content")]
        let provider = AppSyncListProvider(elements: elements, nextToken: "nextToken")
        guard case .loaded = provider.loadedState else {
            XCTFail("Should be loaded")
            return
        }
        let getNextPageComplete = expectation(description: "get next page completed")
        provider.getNextPage { result in
            switch result {
            case .success:
                XCTFail("Should have failed")
            case .failure(let error):
                guard case .listOperation(_, _, let underlyingError) = error,
                      (underlyingError as? GraphQLResponseError<List<Comment4>>) != nil else {
                    XCTFail("Unexpected error \(error)")
                    return
                }
                getNextPageComplete.fulfill()
            }
        }
        wait(for: [getNextPageComplete], timeout: 1)
    }

    func testNotLoadedStateGetNextPageFailure() throws {
        let modelMetadata = AppSyncModelMetadata(appSyncAssociatedId: "postId",
                                                 appSyncAssociatedField: "post",
                                                 apiName: "apiName")
        let provider = AppSyncListProvider<Comment4>(metadata: modelMetadata)
        guard case .notLoaded = provider.loadedState else {
            XCTFail("Should not be loaded")
            return
        }
        let getNextPageComplete = expectation(description: "get next page completed")
        provider.getNextPage { result in
            switch result {
            case .success:
                XCTFail("Should have failed")
            case .failure(let error):
                guard case .clientValidation = error else {
                    XCTFail("Unexpected error \(error)")
                    return
                }
                getNextPageComplete.fulfill()
            }
        }
        wait(for: [getNextPageComplete], timeout: 1)
    }
}
