//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon

class StoragePathTests: XCTestCase {

    /// Given: StringStoragePath object
    /// When: resolve is called
    /// Then: a string storage path is returned
    func testResolveStringStoragePath() {
        let expectedResult = "/my/path"
        let path = StringStoragePath(resolve: { input in return expectedResult})
        let result = path.resolve("input")
        XCTAssertEqual(result, expectedResult)
    }

    /// Given: IdentityIDStoragePath object
    /// When: resolve is called
    /// Then: a string storage path is returned with the identity id included in the path
    func testResolveIdentityIDStoragePath() {
        let identityID = "123"
        let expectedResult = "/my/\(identityID)/path"
        let path = IdentityIDStoragePath(resolve: { id in return "/my/\(id)/path"})
        let result = path.resolve(identityID)
        XCTAssertEqual(result, expectedResult)
    }
}
