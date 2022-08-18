//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify

class ArrayLiteralListProviderTests: XCTestCase {
    struct BasicModel: Model {
        var id: String
    }

    func testLoadSuccess() throws {
        let provider = ArrayLiteralListProvider(elements: [BasicModel(id: "id")])
        let result = provider.load()

        guard case .success(let elements) = result else {
            XCTFail("Should be success")
            return
        }

        XCTAssertEqual(elements.count, 1)
        XCTAssertEqual(elements[0].id, "id")
    }

    func testLoadWithCompletionSuccess() throws {
        let provider = ArrayLiteralListProvider(elements: [BasicModel(id: "id")])
        let loadComplete = expectation(description: "load completed")
        provider.load { result in
            switch result {
            case .success(let elements):
                XCTAssertEqual(elements.count, 1)
                XCTAssertEqual(elements[0].id, "id")
                loadComplete.fulfill()
            case .failure(let coreError):
                XCTFail("\(coreError)")
            }
        }

        wait(for: [loadComplete], timeout: 1)
    }

    func testHasNextPageFalse() {
        let provider = ArrayLiteralListProvider(elements: [BasicModel(id: "id")])
        XCTAssertFalse(provider.hasNextPage())
    }

    func testGetNextPage() {
        let provider = ArrayLiteralListProvider(elements: [BasicModel(id: "id")])
        let getNextPageComplete = expectation(description: "get next page completed")
        provider.getNextPage { result in
            switch result {
            case .success:
                XCTFail("Should have failed")
            case .failure(let coreError):
                guard case .clientValidation = coreError else {
                    XCTFail("Expected client validation error")
                    return
                }
                getNextPageComplete.fulfill()
            }
        }

        wait(for: [getNextPageComplete], timeout: 1)
    }
}
