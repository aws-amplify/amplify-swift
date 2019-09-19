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

class AWSS3StoragePluginBasicIntegrationTests: AWSS3StoragePluginTestBase {

    func testPutData() {
        let key = "testPutData"
        let data = key.data(using: .utf8)!
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Storage.put(key: key, data: data, options: nil) { (event) in
            switch event {
            case .completed:
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Failed with \(error)")
            default:
                break
            }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 60)
    }

    func testPutEmptyData() {
        let key = "testPutEmptyData"
        let data = "".data(using: .utf8)!
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Storage.put(key: key, data: data, options: nil) { (event) in
            switch event {
            case .completed:
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Failed with \(error)")
            default:
                break
            }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 60)
    }

    func testPutDataFromFile() {
        let key = "testPutDataFromFile"
        let filePath = NSTemporaryDirectory() + key + ".tmp"

        let fileURL = URL(fileURLWithPath: filePath)
        FileManager.default.createFile(atPath: filePath, contents: key.data(using: .utf8), attributes: nil)

        let completeInvoked = expectation(description: "Completed is invoked")
        let operation = Amplify.Storage.put(key: key, local: fileURL, options: nil) { (event) in
            switch event {
            case .completed:
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Failed with \(error)")
            default:
                break
            }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 60)
    }

    func testPutEmptyDataFromFile() {
        let key = "testPutEmptyDataFromFile"
        let filePath = NSTemporaryDirectory() + key + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)
        FileManager.default.createFile(atPath: filePath, contents: "".data(using: .utf8), attributes: nil)

        let completeInvoked = expectation(description: "Completed is invoked")
        let operation = Amplify.Storage.put(key: key, local: fileURL, options: nil) { (event) in
            switch event {
            case .completed:
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Failed with \(error)")
            default:
                break
            }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 60)
    }

    func testPutLargeData() {
        let key = "testPutLargeData"
        var testData = key
        for _ in 1...20 {
            testData += testData
        }
        let data = testData.data(using: .utf8)!
        XCTAssertTrue(data.count > 10_000_000, "Could not create data object greater than 10MB")
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Storage.put(key: key, data: data, options: nil) { (event) in
            switch event {
            case .completed:
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Failed with \(error)")
            default:
                break
            }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 60)
    }

    func testPutLargeFile() {
        let key = "testPutLargeFile"
        let filePath = NSTemporaryDirectory() + key + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)

        var testData = key
        for _ in 1...20 {
            testData += testData
        }
        let data = testData.data(using: .utf8)!
        FileManager.default.createFile(atPath: filePath, contents: data, attributes: nil)

        XCTAssertTrue(data.count > 10000000, "Could not create data object greater than 10MB")
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Storage.put(key: key, local: fileURL, options: nil) { (event) in
            switch event {
            case .completed:
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Failed with \(error)")
            default:
                break
            }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 60)
    }

    func testGetDataToMemory() {
        let key = "testGetDataToMemory"
        putData(key: key, data: key.data(using: .utf8)!)
        let completeInvoked = expectation(description: "Completed is invoked")
        let options = StorageGetDataOptions(accessLevel: nil,
                                            targetIdentityId: nil)

        let operation = Amplify.Storage.getData(key: key, options: options) { (event) in
            switch event {
            case .completed:
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Failed with \(error)")
            default:
                break
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 60)
    }

    func testDownloadFile() {
        let key = "testDownloadFile"
        let timestamp = String(Date().timeIntervalSince1970)
        let timestampData = timestamp.data(using: .utf8)!
        putData(key: key, data: timestampData)
        let filePath = NSTemporaryDirectory() + key + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)
        removeIfExists(fileURL)
        let completeInvoked = expectation(description: "Completed is invoked")
        let options = StorageDownloadFileOptions(accessLevel: nil,
                                                 targetIdentityId: nil)

        let operation = Amplify.Storage.downloadFile(key: key, local: fileURL, options: options) { (event) in
            switch event {
            case .completed:
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Failed with \(error)")
            default:
                break
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 60)

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

    func testGetRemoteURL() {
        let key = "testGetRemoteURL"
        putData(key: key, dataString: key)

        var remoteURLOptional: URL?
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Storage.getURL(key: key, options: nil) { (event) in
            switch event {
            case .completed(let result):
                remoteURLOptional = result
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Failed with \(error)")
            default:
                break
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 15)
        guard let remoteURL = remoteURLOptional else {
            XCTFail("Failed to get remoteURL")
            return
        }

        let dataTaskCompleteInvoked = expectation(description: "Completion of retrieving data at URL is invoked")
        let task = URLSession.shared.dataTask(with: remoteURL) { (data, response, error) in
            guard error == nil else {
                XCTFail("Failed to received data from url eith error \(error)")
                return
            }

            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
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

        waitForExpectations(timeout: 15)
    }

    func testListFromPublic() {
        let key = "testListFromPublic"
        putData(key: key, dataString: key)
        let completeInvoked = expectation(description: "Completed is invoked")
        let options = StorageListOptions(accessLevel: .public,
                                        targetIdentityId: nil,
                                        path: key)
        let operation = Amplify.Storage.list(options: options) { (event) in
            switch event {
            case .completed(let result):
                XCTAssertNotNil(result)
                XCTAssertNotNil(result.keys)
                XCTAssertEqual(result.keys.count, 1)
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Failed with \(error)")
            default:
                break
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 100)
    }

    func testListEmpty() {
        let key = "testListEmpty"
        let completeInvoked = expectation(description: "Completed is invoked")
        let options = StorageListOptions(accessLevel: .public,
                                        targetIdentityId: nil,
                                        path: key)
        let operation = Amplify.Storage.list(options: options) { (event) in
            switch event {
            case .completed(let result):
                XCTAssertNotNil(result)
                XCTAssertNotNil(result.keys)
                XCTAssertEqual(result.keys.count, 0)
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Failed with \(error)")
            default:
                break
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 10)
    }

    func testListWithPathUsingFolderNameWithForwardSlash() {
        let key = "testListWithPathUsingFolderNameWithForwardSlash"
        let folder = key + "/"
        var keys: [String] = []
        for fileIndex in 1...10 {
            let key = folder + "file" + String(fileIndex) + ".txt"
            keys.append(key)
            putData(key: key, dataString: key)
        }

        let completeInvoked = expectation(description: "Completed is invoked")
        let options = StorageListOptions(accessLevel: .public,
                                        targetIdentityId: nil,
                                        path: folder)
        let operation = Amplify.Storage.list(options: options) { (event) in
            switch event {
            case .completed(let result):
                XCTAssertNotNil(result)
                XCTAssertNotNil(result.keys)
                XCTAssertEqual(result.keys.count, keys.count)
                for resultKey in result.keys {
                    XCTAssertTrue(keys.contains(resultKey), "The key that was uploaded should match the key listed")
                }

                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Failed with \(error)")
            default:
                break
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 10)
    }

    func testListWithPathUsingIncompleteFolderName() {
        let key1 = "testListWithPathUsingIncomp"
        let key2 = "leteFolderName"
        let folder = key1 + key2 + "/"
        var keys: [String] = []
        for fileIndex in 1...10 {
            let key = folder + "file" + String(fileIndex) + ".txt"
            keys.append(key)
            putData(key: key, dataString: key)
        }

        let completeInvoked = expectation(description: "Completed is invoked")
        let options = StorageListOptions(accessLevel: .public,
                                        targetIdentityId: nil,
                                        path: key1)
        let operation = Amplify.Storage.list(options: options) { (event) in
            switch event {
            case .completed(let result):
                XCTAssertNotNil(result)
                XCTAssertNotNil(result.keys)
                XCTAssertEqual(result.keys.count, keys.count)
                for resultKey in result.keys {
                    XCTAssertTrue(keys.contains(resultKey), "The key that was uploaded should match the key listed")
                }
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Failed with \(error)")
            default:
                break
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 10)
    }

    func testRemoveKey() {
        let key = "testRemoveKey"
        putData(key: key, dataString: key)

        let completeInvoked = expectation(description: "Completed is invoked")
        let removeOperation = Amplify.Storage.remove(key: key, options: nil) { (event) in
            switch event {
            case .completed(let result):
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Failed with \(error)")
            default:
                break
            }
        }
        XCTAssertNotNil(removeOperation)
        waitForExpectations(timeout: 60)
    }

    func testRemoveNonExistentKey() {
        let key = "testRemoveNonExistentKey"

        let completeInvoked = expectation(description: "Completed is invoked")
        let removeOperation = Amplify.Storage.remove(key: key, options: nil) { (event) in
            switch event {
            case .completed(let result):
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Failed with \(error)")
            default:
                break
            }
        }
        XCTAssertNotNil(removeOperation)
        waitForExpectations(timeout: 60)
    }

    func testEscapeHatchAndGetHeadObject() {
        let key = "testEscapeHatchAndGetHeadObject"
        putData(key: key, dataString: key)

        do {
            let pluginOptional = try Amplify.Storage.getPlugin(for: "AWSS3StoragePlugin")

            guard let plugin = pluginOptional as? AWSS3StoragePlugin else {
                XCTFail("Could not cast as AWSS3StoragePlugin")
                return
            }

            let awsS3 = plugin.getEscapeHatch()
            let request: AWSS3HeadObjectRequest = AWSS3HeadObjectRequest()
            if case let .string(bucket) = bucket {
                request.bucket = bucket
            }
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
}
