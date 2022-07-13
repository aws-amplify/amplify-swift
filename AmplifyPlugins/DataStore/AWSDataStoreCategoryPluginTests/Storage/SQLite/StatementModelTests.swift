//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SQLite
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

class StatementModelTests: XCTestCase {

    func testDropLastPath_invalidString() throws {
        let path = "post."
        let result = path.dropLastPath()
        XCTAssertEqual(result, "post")
    }

    func testDropLastPath_emptyString() throws {
        let path = ""
        let result = path.dropLastPath()
        XCTAssertEqual(result, "")
    }

    func testDropLastPath_Root() throws {
        let path = "post"
        let result = path.dropLastPath()
        XCTAssertEqual(result, "post")
    }

    func testDropLastPath_OnePath() throws {
        let path = "post.id"
        let result = path.dropLastPath()
        XCTAssertEqual(result, "post")
    }

    func testDropLastPath_Nested() throws {
        let path = "post.blog.id"
        let result = path.dropLastPath()
        XCTAssertEqual(result, "post.blog")
    }
}
