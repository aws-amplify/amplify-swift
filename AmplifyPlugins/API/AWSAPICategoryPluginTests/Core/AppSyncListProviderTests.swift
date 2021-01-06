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

class AppSyncListProviderTests: XCTestCase {

    func testAppSyncListProviderWithElementsShouldLoad() {
        let elements = [Post4(title: "title"), Post4(title: "title")]
        let listProvider = AppSyncListProvider<Post4>(elements)
        let results = listProvider.load()
        guard case .success(let posts) = results else {
            XCTFail("Should be .success")
            return
        }
        XCTAssertEqual(posts.count, 2)
    }

    func testAppSyncListProviderWithElementsShouldLoadWithCompletion() {
        let elements = [Post4(title: "title"), Post4(title: "title")]
        let listProvider = AppSyncListProvider<Post4>(elements)
        let loadComplete = expectation(description: "Load completed")
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
}
