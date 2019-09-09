//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSMobileClient
import Amplify
import AWSS3StoragePlugin
import AWSS3
class AWSS3StoragePluginNegativeTests: AWSS3StoragePluginTestBase {

    //    // MARK: Negative Tests
    //
    func testGetNonexistentKey() {
        let key = "testGetNonexistentKey"
        let failInvoked = expectation(description: "Failed is invoked")
        let operation = Amplify.Storage.get(key: key, options: nil) { (event) in
            switch event {
            case .completed:
                XCTFail("Should not have completed successfully")
            case .failed(let error):
                // TODO: Check for Error is of type 404 or we made our own.
                failInvoked.fulfill()
            default:
                break
            }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 100)
    }
    //
    //    func testPutDataFromMissingFile() {
    //        XCTFail("Not yet implemented")
    //    }
    //
    //    func testPutDataForEmptyObject() {
    //        XCTFail("Not yet implemented")
    //    }
    //
    //    func testListNonExistentKey() {
    //        XCTFail("Not yet implemented")
    //        // So we should set a custom Prefix since by default it will list from the "public/" folder. we need to..
    //        // change this and test that accessDenied is returned ..
    //    }
    //
    //    func testRemoveNonExistentKey() {
    //        XCTFail("Not yet implemented")
    //    }
}
