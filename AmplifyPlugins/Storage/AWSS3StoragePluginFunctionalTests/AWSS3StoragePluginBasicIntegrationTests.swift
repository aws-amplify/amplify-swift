//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSS3StoragePlugin
import AWSS3
import var CommonCrypto.CC_MD5_DIGEST_LENGTH
import func CommonCrypto.CC_MD5
import typealias CommonCrypto.CC_LONG
@testable import AmplifyTestCommon

// swiftlint:disable:next type_body_length
class AWSS3StoragePluginBasicIntegrationTests: AWSS3StoragePluginTestBase {

    /// Given: An data object
    /// When: Upload the data
    /// Then: The operation completes successfully
    func testUploadData() {
        let key = UUID().uuidString
        let data = key.data(using: .utf8)!
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Storage.uploadData(key: key, data: data, options: nil) { event in
            switch event {
            case .success:
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed with \(error)")
            }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    /// Given: A empty data object
    /// When: Upload the data
    /// Then: The operation completes successfully
    func testUploadEmptyData() {
        let key = UUID().uuidString
        let data = "".data(using: .utf8)!
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Storage.uploadData(key: key, data: data, options: nil) { event in
            switch event {
            case .success:
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed with \(error)")
            }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    /// Given: A file with contents
    /// When: Upload the file
    /// Then: The operation completes successfully
    func testUploadFile() {
        let key = UUID().uuidString
        let filePath = NSTemporaryDirectory() + key + ".tmp"

        let fileURL = URL(fileURLWithPath: filePath)
        FileManager.default.createFile(atPath: filePath, contents: key.data(using: .utf8), attributes: nil)

        let completeInvoked = expectation(description: "Completed is invoked")
        let operation = Amplify.Storage.uploadFile(key: key, local: fileURL, options: nil) { event in
            switch event {
            case .success:
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed with \(error)")
            }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    /// Given: A file with empty contents
    /// When: Upload the file
    /// Then: The operation completes successfully
    func testUploadFileEmptyData() {
        let key = UUID().uuidString
        let filePath = NSTemporaryDirectory() + key + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)
        FileManager.default.createFile(atPath: filePath, contents: "".data(using: .utf8), attributes: nil)

        let completeInvoked = expectation(description: "Completed is invoked")
        let operation = Amplify.Storage.uploadFile(key: key, local: fileURL, options: nil) { event in
            switch event {
            case .success:
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed with \(error)")
            }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    /// Given: A large  data object
    /// When: Upload the data
    /// Then: The operation completes successfully
    func testUploadLargeData() {
        let key = UUID().uuidString
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Storage.uploadData(key: key,
                                                data: AWSS3StoragePluginTestBase.largeDataObject,
                                                options: nil) { event in
            switch event {
            case .success:
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed with \(error)")
            }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    /// Given: A large file
    /// When: Upload the file
    /// Then: The operation completes successfully
    func testUploadLargeFile() {
        let key = UUID().uuidString
        let filePath = NSTemporaryDirectory() + key + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)

        FileManager.default.createFile(atPath: filePath,
                                       contents: AWSS3StoragePluginTestBase.largeDataObject,
                                       attributes: nil)

        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Storage.uploadFile(key: key, local: fileURL, options: nil) { event in
            switch event {
            case .success:
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed with \(error)")
            }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    /// Given: An object in storage
    /// When: Call the downloadData API
    /// Then: The operation completes successfully with the data retrieved
    func testDownloadDataToMemory() {
        let key = UUID().uuidString
        uploadData(key: key, data: key.data(using: .utf8)!)
        let completeInvoked = expectation(description: "Completed is invoked")
        let options = StorageDownloadDataRequest.Options()

        let operation = Amplify.Storage.downloadData(key: key, options: options) { event in
            switch event {
            case .success:
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed with \(error)")
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    /// Given: An object in storage
    /// When: Call the downloadFile API
    /// Then: The operation completes successfully the local file containing the data from the object
    func testDownloadFile() {
        let key = UUID().uuidString
        let timestamp = String(Date().timeIntervalSince1970)
        let timestampData = timestamp.data(using: .utf8)!
        uploadData(key: key, data: timestampData)
        let filePath = NSTemporaryDirectory() + key + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)
        removeIfExists(fileURL)
        let completeInvoked = expectation(description: "Completed is invoked")
        let options = StorageDownloadFileRequest.Options()

        let operation = Amplify.Storage.downloadFile(key: key, local: fileURL, options: options) { event in
            switch event {
            case .success:
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed with \(error)")
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)

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
    func testGetRemoteURL() {
        let key = UUID().uuidString
        uploadData(key: key, dataString: key)

        var remoteURLOptional: URL?
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Storage.getURL(key: key, options: nil) { event in
            switch event {
            case .success(let result):
                remoteURLOptional = result
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed with \(error)")
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
        guard let remoteURL = remoteURLOptional else {
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

        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    /// Given: An object in storage
    /// When: Call the list API
    /// Then: The operation completes successfully with the key retrieved
    func testListFromPublic() {
        let key = UUID().uuidString
        let expectedMD5Hex = MD5(string: key).map { String(format: "%02hhx", $0) }.joined()
        uploadData(key: key, dataString: key)
        let completeInvoked = expectation(description: "Completed is invoked")
        let options = StorageListRequest.Options(accessLevel: .guest,
                                                 targetIdentityId: nil,
                                                 path: key)
        let operation = Amplify.Storage.list(options: options) { event in
            switch event {
            case .success(let result):
                XCTAssertNotNil(result)
                XCTAssertNotNil(result.items)
                XCTAssertEqual(result.items.count, 1)
                if let item = result.items.first {
                    print(item)
                    XCTAssertEqual(item.key, key)
                    XCTAssertNotNil(item.eTag)
                    XCTAssertEqual(item.eTag, expectedMD5Hex)
                    XCTAssertNotNil(item.lastModified)
                    XCTAssertNotNil(item.size)
                }

                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed with \(error)")
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    /// Given: No object in storage for the key
    /// When: Call the list API
    /// Then: The operation completes successfully with empty list of keys returned
    func testListEmpty() {
        let key = UUID().uuidString
        let completeInvoked = expectation(description: "Completed is invoked")
        let options = StorageListRequest.Options(accessLevel: .guest,
                                                 targetIdentityId: nil,
                                                 path: key)
        let operation = Amplify.Storage.list(options: options) { event in
            switch event {
            case .success(let result):
                XCTAssertNotNil(result)
                XCTAssertNotNil(result.items)
                XCTAssertEqual(result.items.count, 0)
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed with \(error)")
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    /// Given: No object in storage for the key
    /// When: Call the list API
    /// Then: The operation completes successfully with empty list of keys returned
    func testListWithPathUsingFolderNameWithForwardSlash() {
        let key = UUID().uuidString
        let folder = key + "/"
        var keys: [String] = []
        for fileIndex in 1 ... 10 {
            let key = folder + "file" + String(fileIndex) + ".txt"
            keys.append(key)
            uploadData(key: key, dataString: key)
        }

        let completeInvoked = expectation(description: "Completed is invoked")
        let options = StorageListRequest.Options(accessLevel: .guest,
                                                 targetIdentityId: nil,
                                                 path: folder)
        let operation = Amplify.Storage.list(options: options) { event in
            switch event {
            case .success(let result):
                XCTAssertNotNil(result)
                XCTAssertNotNil(result.items)
                XCTAssertEqual(result.items.count, keys.count)
                for item in result.items {
                    XCTAssertTrue(keys.contains(item.key), "The key that was uploaded should match the key listed")
                }

                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed with \(error)")
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    /// Given: Objects with identifiers specified in `keys` array stored in folder named (`key1`+`key2`)
    /// When: Call the list API using the path `key1`
    /// Then: The operation completes successfully with list of keys returned from the folder.
    func testListWithPathUsingIncompleteFolderName() {
        let key1 = UUID().uuidString + "testListWithPathUsingIncomp"
        let key2 = "leteFolderName"
        let folder = key1 + key2 + "/"
        var keys: [String] = []
        for fileIndex in 1 ... 10 {
            let key = folder + "file" + String(fileIndex) + ".txt"
            keys.append(key)
            uploadData(key: key, dataString: key)
        }

        let completeInvoked = expectation(description: "Completed is invoked")
        let options = StorageListRequest.Options(accessLevel: .guest,
                                                 targetIdentityId: nil,
                                                 path: key1)
        let operation = Amplify.Storage.list(options: options) { event in
            switch event {
            case .success(let result):
                XCTAssertNotNil(result)
                XCTAssertNotNil(result.items)
                XCTAssertEqual(result.items.count, keys.count)
                for item in result.items {
                    XCTAssertTrue(keys.contains(item.key), "The key that was uploaded should match the key listed")
                }
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed with \(error)")
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    /// Given: An object in storage
    /// When: Call the remove API
    /// Then: The operation completes successfully with the key removed from storage
    func testRemoveKey() {
        let key = UUID().uuidString
        uploadData(key: key, dataString: key)

        let completeInvoked = expectation(description: "Completed is invoked")
        let removeOperation = Amplify.Storage.remove(key: key, options: nil) { event in
            switch event {
            case .success:
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed with \(error)")
            }
        }
        XCTAssertNotNil(removeOperation)
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    /// Given: Object with key `key` does not exist in storage
    /// When: Call the remove API
    /// Then: The operation completes successfully.
    func testRemoveNonExistentKey() {
        let key = UUID().uuidString

        let completeInvoked = expectation(description: "Completed is invoked")
        let removeOperation = Amplify.Storage.remove(key: key, options: nil) { event in
            switch event {
            case .success:
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed with \(error)")
            }
        }
        XCTAssertNotNil(removeOperation)
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    /// Given: Object with key `key` in storage
    /// When: Using the escape hatch and calling headObject API  using the key "public/`key`"
    /// Then: The request completes successful
    func testEscapeHatchAndGetHeadObject() {
        let key = UUID().uuidString
        uploadData(key: key, dataString: key)

        do {
            let pluginOptional = try Amplify.Storage.getPlugin(for: "awsS3StoragePlugin")

            guard let plugin = pluginOptional as? AWSS3StoragePlugin else {
                XCTFail("Could not cast as AWSS3StoragePlugin")
                return
            }

            let awsS3 = plugin.getEscapeHatch()
            let request: AWSS3HeadObjectRequest = AWSS3HeadObjectRequest()

            request.bucket = try AWSS3StoragePluginTestBase.getBucketFromConfig(
                forResource: AWSS3StoragePluginTestBase.amplifyConfiguration)
            request.key = "public/" + key

            let task = awsS3.headObject(request)
            task.waitUntilFinished()

            if let error = task.error {
                XCTFail("Failed to get headObject \(error)")
            } else if let result = task.result {
                print("headObject \(result)")
                XCTAssertNotNil(result)
            }
        } catch {
            XCTFail("Failed to get AWSS3StoragePlugin")
        }
    }

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
} // swiftlint:disable:this file_length
