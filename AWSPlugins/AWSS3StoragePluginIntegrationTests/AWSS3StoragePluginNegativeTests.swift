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

    func testGetNonexistentKey() {
        let key = "testGetNonexistentKey"
        let failInvoked = expectation(description: "Failed is invoked")
        let options = StorageGetOption(accessLevel: nil,
                                       targetIdentityId: nil,
                                       storageGetDestination: .data,
                                       options: nil)
        let operation = Amplify.Storage.get(key: key, options: options) { (event) in
            switch event {
            case .completed:
                XCTFail("Should not have completed successfully")
            case .failed(let error):
                guard case let .notFound(errorDescription, _) = error else {
                    XCTFail("Should have been validation error")
                    return
                }

                XCTAssertEqual(errorDescription, StorageErrorConstants.KeyNotFound.ErrorDescription)
                failInvoked.fulfill()
            default:
                break
            }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 10)
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
