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
class AWSS3StoragePluginOptionsUsabilityTests: AWSS3StoragePluginTestBase {

//    func testPutLargeDataWithMultiPart() {
//        XCTFail("Not yet implemented")
//    }
//
    // Retrieve a URL which expires in 15 seconds.
//    func testGetRemoteURLWithExpires() {
//
//        let key = "testGetRemoteURLWithExpires"
//        putData(key: key, dataString: key)
//
//        var remoteURLOptional: URL?
//        let completeInvoked = expectation(description: "Completed is invoked")
//
//        let operation = Amplify.Storage.get(key: key, options: nil) { (event) in
//            switch event {
//            case .completed(let result):
//                if let result = result.remote {
//                    remoteURLOptional = result
//                } else {
//                    XCTFail("Missing remote url from result")
//                }
//                completeInvoked.fulfill()
//            case .failed(let error):
//                XCTFail("Failed with \(error)")
//            default:
//                break
//            }
//        }
//        XCTAssertNotNil(operation)
//        waitForExpectations(timeout: 15)
//        guard let remoteURL = remoteURLOptional else {
//            XCTFail("Failed to get remoteURL")
//            return
//        }
//
//        let dataTaskCompleteInvoked = expectation(description: "Completion of retrieving data at URL is invoked")
//        let task = URLSession.shared.dataTask(with: remoteURL) { (data, response, error) in
//            guard error == nil else {
//                XCTFail("Failed to received data from url eith error \(error)")
//                return
//            }
//
//            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
//                XCTFail("Failed to received data with bad status code")
//                return
//            }
//
//            guard let data = data else {
//                XCTFail("Failed to received data, empty data object")
//                return
//            }
//
//            let dataString = String(data: data, encoding: .utf8)!
//            XCTAssertEqual(dataString, key)
//            dataTaskCompleteInvoked.fulfill()
//        }
//        task.resume()
//
//        waitForExpectations(timeout: 15)
//    }
//
//    func testPutWithMetadata() {
//        XCTFail("Not yet implemented")
//    }
//
//    func testPutWithTags() {
//        XCTFail("Not yet implemented")
//    }
//
//    func testListWithLimit() {
//        XCTFail("Not yet implemented")
//    }

}
