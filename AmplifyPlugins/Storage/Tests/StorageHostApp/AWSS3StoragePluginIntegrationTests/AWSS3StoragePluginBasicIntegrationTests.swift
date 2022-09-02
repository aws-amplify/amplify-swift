//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSS3StoragePlugin
import var CommonCrypto.CC_MD5_DIGEST_LENGTH
import func CommonCrypto.CC_MD5
import typealias CommonCrypto.CC_LONG
import AmplifyAsyncTesting

class AWSS3StoragePluginBasicIntegrationTests: AWSS3StoragePluginTestBase {

    /// Given: An data object
    /// When: Upload the data
    /// Then: The operation completes successfully
    func testUploadData() async {
        let key = UUID().uuidString
        let data = key.data(using: .utf8)!
        let completeInvoked = asyncExpectation(description: "Completed is invoked")
        await wait(with: completeInvoked) {
            return try await Amplify.Storage.uploadData(key: key, data: data, options: nil).value
        }
    }

    /// Given: A empty data object
    /// When: Upload the data
    /// Then: The operation completes successfully
    func testUploadEmptyData() async {
        let key = UUID().uuidString
        let data = "".data(using: .utf8)!
        let completeInvoked = asyncExpectation(description: "Completed is invoked")
        await wait(with: completeInvoked) {
            return try await Amplify.Storage.uploadData(key: key, data: data, options: nil).value
        }
    }

    /// Given: A file with contents
    /// When: Upload the file
    /// Then: The operation completes successfully
    func testUploadFile() async {
        let key = UUID().uuidString
        let filePath = NSTemporaryDirectory() + key + ".tmp"

        let fileURL = URL(fileURLWithPath: filePath)
        FileManager.default.createFile(atPath: filePath, contents: key.data(using: .utf8), attributes: nil)

        let completeInvoked = asyncExpectation(description: "Completed is invoked")
        await wait(with: completeInvoked) {
            return try await Amplify.Storage.uploadFile(key: key, local: fileURL, options: nil).value
        }
    }

    /// Given: A file with empty contents
    /// When: Upload the file
    /// Then: The operation completes successfully
    func testUploadFileEmptyData() async {
        let key = UUID().uuidString
        let filePath = NSTemporaryDirectory() + key + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)
        FileManager.default.createFile(atPath: filePath, contents: "".data(using: .utf8), attributes: nil)

        let completeInvoked = asyncExpectation(description: "Completed is invoked")
        await wait(with: completeInvoked) {
            return try await Amplify.Storage.uploadFile(key: key, local: fileURL, options: nil).value
        }
    }

    /// Given: A large  data object
    /// When: Upload the data
    /// Then: The operation completes successfully
    func testUploadLargeData() async {
        let key = UUID().uuidString
        let completeInvoked = asyncExpectation(description: "Completed is invoked")
        await wait(with: completeInvoked) {
            return try await Amplify.Storage.uploadData(key: key,
                                                        data: AWSS3StoragePluginTestBase.largeDataObject,
                                                        options: nil).value
        }
    }

    /// Given: A large file
    /// When: Upload the file
    /// Then: The operation completes successfully
    func testUploadLargeFile() async {
        let key = UUID().uuidString
        let filePath = NSTemporaryDirectory() + key + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)

        FileManager.default.createFile(atPath: filePath,
                                       contents: AWSS3StoragePluginTestBase.largeDataObject,
                                       attributes: nil)

        let completeInvoked = asyncExpectation(description: "Completed is invoked")
        await wait(with: completeInvoked, timeout: 600) {
            return try await Amplify.Storage.uploadFile(key: key, local: fileURL, options: nil).value
        }
    }

    /// Given: An object in storage
    /// When: Call the downloadData API
    /// Then: The operation completes successfully with the data retrieved
    func testDownloadDataToMemory() async {
        let key = UUID().uuidString
        await uploadData(key: key, data: key.data(using: .utf8)!)
        let completeInvoked = asyncExpectation(description: "Completed is invoked")
        await wait(with: completeInvoked) {
            return try await Amplify.Storage.downloadData(key: key, options: .init()).value
        }
    }

    /// Given: An object in storage
    /// When: Call the downloadFile API
    /// Then: The operation completes successfully the local file containing the data from the object
    func testDownloadFile() async {
        let key = UUID().uuidString
        let timestamp = String(Date().timeIntervalSince1970)
        let timestampData = timestamp.data(using: .utf8)!
        await uploadData(key: key, data: timestampData)
        let filePath = NSTemporaryDirectory() + key + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)
        removeIfExists(fileURL)

        let completeInvoked = asyncExpectation(description: "Completed is invoked")
        await wait(with: completeInvoked) {
            return try await Amplify.Storage.downloadFile(key: key, local: fileURL, options: .init()).value
        }

        let fileExists = FileManager.default.fileExists(atPath: fileURL.path)
        XCTAssertTrue(fileExists)
        do {
            let result = try String(contentsOf: fileURL, encoding: .utf8)
            XCTAssertEqual(result, timestamp)
        } catch {
            XCTFail("Failed to read file that has been downloaded to")
        }
        removeIfExists(fileURL)
    }

    /// Given: An object in storage
    /// When: Call the getURL API
    /// Then: The operation completes successfully with the URL retrieved
    func testGetRemoteURL() async {
        let key = UUID().uuidString
        await uploadData(key: key, dataString: key)

        guard let remoteURL = await getURL(key: key) else {
            XCTFail("Failed to get remoteURL")
            return
        }

        let dataTaskCompleteInvoked = expectation(description: "Completion of retrieving data at URL is invoked")
        let task = URLSession.shared.dataTask(with: remoteURL) { data, response, error in
            if let error = error {
                XCTFail("Failed to received data from url with error \(error)")
                dataTaskCompleteInvoked.fulfill()
                return
            }

            guard let response = response as? HTTPURLResponse, (200 ... 299).contains(response.statusCode) else {
                XCTFail("Failed to received data with bad status code")
                dataTaskCompleteInvoked.fulfill()
                return
            }

            guard let data = data else {
                XCTFail("Failed to received data, empty data object")
                dataTaskCompleteInvoked.fulfill()
                return
            }

            let dataString = String(data: data, encoding: .utf8)!
            XCTAssertEqual(dataString, key)
            dataTaskCompleteInvoked.fulfill()
        }
        task.resume()

        await waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    /// Given: An object in storage
    /// When: Call the list API
    /// Then: The operation completes successfully with the key retrieved
    func testListFromPublic() async {
        let key = UUID().uuidString
        let expectedMD5Hex = "\"\(MD5(string: key).map { String(format: "%02hhx", $0) }.joined())\""
        await uploadData(key: key, dataString: key)
        let completeInvoked = asyncExpectation(description: "Completed is invoked")
        let options = StorageListRequest.Options(accessLevel: .guest,
                                                 targetIdentityId: nil,
                                                 path: key)
        let result = await wait(with: completeInvoked) {
            return try await Amplify.Storage.list(options: options)
        }

        guard let items = result?.items else {
            XCTFail("Failed to list items")
            return
        }

        XCTAssertEqual(items.count, 1)
        if let item = items.first {
            XCTAssertEqual(item.key, key)
            XCTAssertNotNil(item.eTag)
            XCTAssertEqual(item.eTag, expectedMD5Hex)
            XCTAssertNotNil(item.lastModified)
            XCTAssertNotNil(item.size)
        }
    }

    /// Given: No object in storage for the key
    /// When: Call the list API
    /// Then: The operation completes successfully with empty list of keys returned
    func testListEmpty() async {
        let key = UUID().uuidString
        let completeInvoked = asyncExpectation(description: "Completed is invoked")
        let options = StorageListRequest.Options(accessLevel: .guest,
                                                 targetIdentityId: nil,
                                                 path: key)
        let result = await wait(with: completeInvoked) {
            return try await Amplify.Storage.list(options: options)
        }

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.items.count, 0)
    }

    /// Given: No object in storage for the key
    /// When: Call the list API
    /// Then: The operation completes successfully with empty list of keys returned
    func testListWithPathUsingFolderNameWithForwardSlash() async {
        let key = UUID().uuidString
        let folder = key + "/"
        var keys: [String] = []
        for fileIndex in 1 ... 10 {
            let key = folder + "file" + String(fileIndex) + ".txt"
            keys.append(key)
            await uploadData(key: key, dataString: key)
        }
        let completeInvoked = asyncExpectation(description: "Completed is invoked")
        let options = StorageListRequest.Options(accessLevel: .guest,
                                                 targetIdentityId: nil,
                                                 path: folder)
        let result = await wait(with: completeInvoked) {
            return try await Amplify.Storage.list(options: options)
        }

        guard let items = result?.items else {
            XCTFail("Failed to list items")
            return
        }

        XCTAssertEqual(items.count, keys.count)
        for item in items {
            XCTAssertTrue(keys.contains(item.key), "The key that was uploaded should match the key listed")
        }
    }

    /// Given: Objects with identifiers specified in `keys` array stored in folder named (`key1`+`key2`)
    /// When: Call the list API using the path `key1`
    /// Then: The operation completes successfully with list of keys returned from the folder.
    func testListWithPathUsingIncompleteFolderName() async {
        let key1 = UUID().uuidString + "testListWithPathUsingIncomp"
        let key2 = "leteFolderName"
        let folder = key1 + key2 + "/"
        var keys: [String] = []
        for fileIndex in 1 ... 10 {
            let key = folder + "file" + String(fileIndex) + ".txt"
            keys.append(key)
            await uploadData(key: key, dataString: key)
        }

        let completeInvoked = asyncExpectation(description: "Completed is invoked")
        let options = StorageListRequest.Options(accessLevel: .guest,
                                                 targetIdentityId: nil,
                                                 path: key1)
        let result = await wait(with: completeInvoked) {
            return try await Amplify.Storage.list(options: options)
        }

        guard let items = result?.items else {
            XCTFail("Failed to list items")
            return
        }

        XCTAssertEqual(items.count, keys.count)
        for item in items {
            XCTAssertTrue(keys.contains(item.key), "The key that was uploaded should match the key listed")
        }
    }

    /// Given: An object in storage
    /// When: Call the remove API
    /// Then: The operation completes successfully with the key removed from storage
    func testRemoveKey() async {
        let key = UUID().uuidString
        await uploadData(key: key, dataString: key)

        let completeInvoked = asyncExpectation(description: "Completed is invoked")
        let result = await wait(with: completeInvoked) {
            return try await Amplify.Storage.remove(key: key, options: nil)
        }
        XCTAssertNotNil(result)
    }

    /// Given: Object with key `key` does not exist in storage
    /// When: Call the remove API
    /// Then: The operation completes successfully.
    func testRemoveNonExistentKey() async {
        let key = UUID().uuidString

        let completeInvoked = asyncExpectation(description: "Completed is invoked")
        let result = await wait(with: completeInvoked) {
            return try await Amplify.Storage.remove(key: key, options: nil)
        }
        XCTAssertNotNil(result)
    }

//    /// Given: Object with key `key` in storage
//    /// When: Using the escape hatch and calling headObject API  using the key "public/`key`"
//    /// Then: The request completes successful
//    func testEscapeHatchAndGetHeadObject() {
//        let key = UUID().uuidString
//        uploadData(key: key, dataString: key)
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
//
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
//                print("headObject \(result)")
//                XCTAssertNotNil(result)
//            }
//        } catch {
//            XCTFail("Failed to get AWSS3StoragePlugin")
//        }
//    }

    // MARK: Helper functions

    func removeIfExists(_ fileURL: URL) {
        let fileExists = FileManager.default.fileExists(atPath: fileURL.path)
        if fileExists {
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                XCTFail("Failed to delete file at \(fileURL)")
            }
        }
    }

    // Copied from accepted answer here:
    // https://stackoverflow.com/questions/32163848/how-can-i-convert-a-string-to-an-md5-hash-in-ios-using-swift
    func MD5(string: String) -> Data {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        let messageData = string.data(using: .utf8)!
        var digestData = Data(count: length)

        _ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
            messageData.withUnsafeBytes { messageBytes -> UInt8 in
                if let messageBytesBaseAddress = messageBytes.baseAddress,
                    let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
                    let messageLength = CC_LONG(messageData.count)
                    CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
                }
                return 0
            }
        }
        return digestData
    }
}
