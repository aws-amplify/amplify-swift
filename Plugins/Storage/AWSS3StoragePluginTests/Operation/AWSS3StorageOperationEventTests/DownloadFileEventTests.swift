//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSS3StoragePlugin

class DownloadFileEventTests: AWSS3StoragePluginTests {

    override func setUp() {
        Amplify.reset()
        let config = AmplifyConfiguration()
        do {
            try Amplify.configure(config)
        } catch {
            XCTFail("Error setting up Amplify: \(error)")
        }
    }

    override func tearDown() {
        Amplify.reset()
    }

//    func testOperation() throws {
//        XCTFail("Not yet implemented")
////        let operation = AWSS3StorageDownloadFileOperation()
//    }
}
