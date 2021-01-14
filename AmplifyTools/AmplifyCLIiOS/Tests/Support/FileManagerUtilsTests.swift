//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

class FileManagerUtilsTests: XCTestCase {
    let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path

    func testShouldResolveHomeDirectory() throws {
        let basePath = "Project/AmplifyApp"
        let resolved = FileManager.default.resolveHomeDirectoryIn(path: "~/\(basePath)")
        XCTAssertEqual(resolved, "\(homeDirectory)/\(basePath)")
    }

    func testShouldNotResolveAnAbsolutePath() throws {
        let basePath = "/Project/AmplifyApp"
        let resolved = FileManager.default.resolveHomeDirectoryIn(path: basePath)
        XCTAssertEqual(resolved, basePath)
    }

    func testShouldNotResolveARelativePath() throws {
        let basePath = "./Project/AmplifyApp"
        let resolved = FileManager.default.resolveHomeDirectoryIn(path: basePath)
        XCTAssertEqual(resolved, basePath)
    }

}
