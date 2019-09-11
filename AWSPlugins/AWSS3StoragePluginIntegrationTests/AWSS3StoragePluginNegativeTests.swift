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

    func testPutDataFromMissingFile() {
        let key = "testPutDataFromMissingFile"
        let filePath = NSTemporaryDirectory() + key + ".tmp"
        var testData = key
        for _ in 1...5 {
            testData += testData
        }
        let fileURL = URL(fileURLWithPath: filePath)
        let failedInvoked = expectation(description: "Failed is invoked")
        let operation = Amplify.Storage.put(key: key, local: fileURL, options: nil) { (event) in
            switch event {
            case .completed:
                XCTFail("Completed event is received")
            case .failed(let error):
                guard case let .missingFile = error else {
                    XCTFail("Should have been missing File error")
                    return
                }
                failedInvoked.fulfill()
            default:
                break
            }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 10)
    }

    // TODO: possibly after understanding content-type
//    func testPutWithInvalidContentType() {
//
//    }
}
