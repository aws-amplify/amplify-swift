//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import AWSS3StoragePlugin
import AWSS3

class AWSS3StoragePluginOptionsUsabilityTests: AWSS3StoragePluginTestBase {

    /// Given: An object in storage
    /// When: Call the GetURL API with 10 second expiry time
    /// Then: Retrieve data successfully when the URL has not expired and fail to after the expiry time
    func testGetRemoteURLWithExpires() async throws {
        let key = UUID().uuidString
        await uploadData(key: key, dataString: key)

        let expires = 10
        let options = StorageGetURLRequest.Options(expires: expires)
        guard let remoteURL = await getURL(key: key, options: options) else {
            XCTFail("Failed to get remoteURL")
            return
        }

        let dataTaskCompleteInvoked = expectation(description: "Completion of retrieving data at URL is invoked")
        let task = URLSession.shared.dataTask(with: remoteURL) { data, response, error in
            if let error = error {
                XCTFail("Failed to received data from url with error \(error)")
                return
            }

            guard let response = response as? HTTPURLResponse, (200 ... 299).contains(response.statusCode) else {
                XCTFail("Failed to received data with bad status code")
                return
            }

            guard let data = data else {
                XCTFail("Failed to received data, empty data object")
                return
            }

            let dataString = String(data: data, encoding: .utf8)!
            XCTAssertEqual(dataString, key)
            dataTaskCompleteInvoked.fulfill()
        }
        task.resume()
        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)

        try await Task.sleep(seconds: 15)

        let urlExpired = expectation(description: "Retrieving expired url should have bad response")
        let task2 = URLSession.shared.dataTask(with: remoteURL) { _, response, error in
            if let error = error {
                XCTFail("Failed to received data from url with error \(error)")
                return
            }

            guard let response = response as? HTTPURLResponse else {
                XCTFail("Could not get response")
                return
            }

            XCTAssertEqual(response.statusCode, 403)
            urlExpired.fulfill()
        }
        task2.resume()
        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)
        
        // Remove the key
        await remove(key: key)
    }

//    /// Given: An object uploaded with metadata with key `metadataKey` and value `metadataValue`
//    /// When: Call the headObject API
//    /// Then: The expected metadata should exist on the object
//    func testuploadExpectationWithMetadata() {
//        let key = UUID().uuidString
//        let data = key.data(using: .utf8)!
//        let metadataKey = "metadatakey"
//        let metadataValue = metadataKey + "Value"
//        let metadata = [metadataKey: metadataValue]
//        let options = StorageUploadDataRequest.Options(metadata: metadata)
//        let completeInvoked = expectation(description: "Completed is invoked")
//
//        let operation = Amplify.Storage.uploadData(key: key, data: data, options: options) { event in
//            switch event {
//            case .success:
//                completeInvoked.fulfill()
//            case .failure(let error):
//                XCTFail("Failed with \(error)")
//            }
//        }
//
//        XCTAssertNotNil(operation)
//        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
//
//        do {
//            let pluginOptional = try Amplify.Storage.getPlugin(for: "awsS3StoragePlugin")
//
//            guard let plugin = pluginOptional as? AWSS3StoragePlugin else {
//                XCTFail("Could not cast as AWSS3StoragePlugin")
//                return
//            }
//
//            let awsS3 = plugin.getEscapeHatch()
//            let request: AWSS3HeadObjectRequest = AWSS3HeadObjectRequest()
//            request.bucket = try AWSS3StoragePluginTestBase.getBucketFromConfig(
//                forResource: AWSS3StoragePluginTestBase.amplifyConfiguration)
//            request.key = "public/" + key
//
//            let task = awsS3.headObject(request)
//            task.waitUntilFinished()
//
//            if let error = task.error {
//                XCTFail("Failed to get headObject \(error)")
//            } else if let result = task.result {
//                let headObjectOutput = result as AWSS3HeadObjectOutput
//                print("headObject \(result)")
//                XCTAssertNotNil(headObjectOutput)
//                XCTAssertNotNil(headObjectOutput.metadata)
//                if let metadata = headObjectOutput.metadata {
//                    XCTAssertEqual(metadata[metadataKey], metadataValue)
//                }
//            }
//        } catch {
//            XCTFail("Failed to get awsS3StoragePlugin")
//        }
//    }

//    func testPutLargeDataWithMetadata() {
//        XCTFail("Not yet implemented")
//    }
//
//    func testPutWithContentType() {
//        XCTFail("Not yet implemented")
//    }
//
//    func testPutWithTags() {
//        XCTFail("Not yet implemented")
//    }
//
//    func testPutLargeDataWithMultiPart() {
//        XCTFail("Not yet implemented")
//    }
}
