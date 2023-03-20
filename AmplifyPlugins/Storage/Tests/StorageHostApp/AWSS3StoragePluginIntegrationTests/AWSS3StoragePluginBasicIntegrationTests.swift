//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSS3StoragePlugin
import CryptoKit

class AWSS3StoragePluginBasicIntegrationTests: AWSS3StoragePluginTestBase {

    /// Given: An data object
    /// When: Upload the data
    /// Then: The operation completes successfully
    func testUploadData() async throws {
        let key = UUID().uuidString
        let data = key.data(using: .utf8)!
        _ = try await Amplify.Storage.uploadData(key: key, data: data, options: nil).value
        
        // Remove the key
        await remove(key: key)
    }

    /// Given: A empty data object
    /// When: Upload the data
    /// Then: The operation completes successfully
    func testUploadEmptyData() async throws {
        let key = UUID().uuidString
        let data = "".data(using: .utf8)!
        _ = try await Amplify.Storage.uploadData(key: key, data: data, options: nil).value

        // Remove the key
        await remove(key: key)
    }

    /// Given: A file with contents
    /// When: Upload the file
    /// Then: The operation completes successfully
    func testUploadFile() async throws {
        let key = UUID().uuidString
        let filePath = NSTemporaryDirectory() + key + ".tmp"

        let fileURL = URL(fileURLWithPath: filePath)
        FileManager.default.createFile(atPath: filePath, contents: key.data(using: .utf8), attributes: nil)

        _ = try await Amplify.Storage.uploadFile(key: key, local: fileURL, options: nil).value
        // Remove the key
        await remove(key: key)
    }

    /// Given: A file with empty contents
    /// When: Upload the file
    /// Then: The operation completes successfully
    func testUploadFileEmptyData() async throws {
        let key = UUID().uuidString
        let filePath = NSTemporaryDirectory() + key + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)
        FileManager.default.createFile(atPath: filePath, contents: "".data(using: .utf8), attributes: nil)

        _ = try await Amplify.Storage.uploadFile(key: key, local: fileURL, options: nil).value
        // Remove the key
        await remove(key: key)
    }

    /// Given: A large  data object
    /// When: Upload the data
    /// Then: The operation completes successfully
    func testUploadLargeData() async throws {
        let key = UUID().uuidString

        let uploadKey = try await Amplify.Storage.uploadData(key: key,
                                                             data: AWSS3StoragePluginTestBase.largeDataObject,
                                                             options: nil).value
        XCTAssertEqual(uploadKey, key)

        try await Amplify.Storage.remove(key: key)
    }

    /// Given: A large file
    /// When: Upload the file
    /// Then: The operation completes successfully
    func testUploadLargeFile() async throws {
        let key = UUID().uuidString
        let filePath = NSTemporaryDirectory() + key + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)

        FileManager.default.createFile(atPath: filePath,
                                       contents: AWSS3StoragePluginTestBase.largeDataObject,
                                       attributes: nil)

        _ = try await Amplify.Storage.uploadFile(key: key, local: fileURL, options: nil).value
        // Remove the key
        await remove(key: key)
    }

    /// Given: An object in storage
    /// When: Call the downloadData API
    /// Then: The operation completes successfully with the data retrieved
    func testDownloadDataToMemory() async throws {
        let key = UUID().uuidString
        await uploadData(key: key, data: key.data(using: .utf8)!)
        _ = try await Amplify.Storage.downloadData(key: key, options: .init()).value
        // Remove the key
        await remove(key: key)
    }

    /// Given: An object in storage
    /// When: Call the downloadFile API
    /// Then: The operation completes successfully the local file containing the data from the object
    func testDownloadFile() async throws {
        let key = UUID().uuidString
        let timestamp = String(Date().timeIntervalSince1970)
        let timestampData = timestamp.data(using: .utf8)!
        await uploadData(key: key, data: timestampData)
        let filePath = NSTemporaryDirectory() + key + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)
        removeIfExists(fileURL)

        _ = try await Amplify.Storage.downloadFile(key: key, local: fileURL, options: .init()).value

        let fileExists = FileManager.default.fileExists(atPath: fileURL.path)
        XCTAssertTrue(fileExists)
        do {
            let result = try String(contentsOf: fileURL, encoding: .utf8)
            XCTAssertEqual(result, timestamp)
        } catch {
            XCTFail("Failed to read file that has been downloaded to")
        }
        removeIfExists(fileURL)
        // Remove the key
        await remove(key: key)
    }

    /// Given: An object in storage
    /// When: Call the getURL API
    /// Then: The operation completes successfully with the URL retrieved
    func testGetRemoteURL() async throws {
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
        
        // Remove the key
        await remove(key: key)
    }

    /// Given: An object in storage
    /// When: Call the list API
    /// Then: The operation completes successfully with the key retrieved
    func testListFromPublic() async throws {
        let key = UUID().uuidString
        let expectedMD5Hex = "\"\(key.md5())\""
        await uploadData(key: key, dataString: key)
        let options = StorageListRequest.Options(accessLevel: .guest,
                                                 targetIdentityId: nil,
                                                 path: key)
        let result = try await Amplify.Storage.list(options: options)
        let items = try XCTUnwrap(result.items)

        XCTAssertEqual(items.count, 1, String(describing: items))
        let item = try XCTUnwrap(items.first)
        XCTAssertEqual(item.key, key)
        XCTAssertNotNil(item.eTag)
        XCTAssertEqual(item.eTag, expectedMD5Hex)
        XCTAssertNotNil(item.lastModified)
        XCTAssertNotNil(item.size)

        // Remove the key
        await remove(key: key)
    }

    /// Given: No object in storage for the key
    /// When: Call the list API
    /// Then: The operation completes successfully with empty list of keys returned
    func testListEmpty() async throws {
        let key = UUID().uuidString
        let options = StorageListRequest.Options(accessLevel: .guest,
                                                 targetIdentityId: nil,
                                                 path: key)
        let result = try await Amplify.Storage.list(options: options)

        XCTAssertNotNil(result)
        XCTAssertEqual(result.items.count, 0)
    }

    /// Given: No object in storage for the key
    /// When: Call the list API
    /// Then: The operation completes successfully with empty list of keys returned
    func testListWithPathUsingFolderNameWithForwardSlash() async throws {
        let key = UUID().uuidString
        let folder = key + "/"
        var keys: [String] = []
        for fileIndex in 1 ... 10 {
            let key = folder + "file" + String(fileIndex) + ".txt"
            keys.append(key)
            await uploadData(key: key, dataString: key)
        }
        let options = StorageListRequest.Options(accessLevel: .guest,
                                                 targetIdentityId: nil,
                                                 path: folder)
        let result = try await Amplify.Storage.list(options: options)
        let items = result.items

        XCTAssertEqual(items.count, keys.count)
        for item in items {
            XCTAssertTrue(keys.contains(item.key), "The key that was uploaded should match the key listed")
        }
        
        // Remove the key
        await remove(key: key)
    }

    /// Given: Objects with identifiers specified in `keys` array stored in folder named (`key1`+`key2`)
    /// When: Call the list API using the path `key1`
    /// Then: The operation completes successfully with list of keys returned from the folder.
    func testListWithPathUsingIncompleteFolderName() async throws {
        let key1 = UUID().uuidString + "testListWithPathUsingIncomp"
        let key2 = "leteFolderName"
        let folder = key1 + key2 + "/"
        var keys: [String] = []
        for fileIndex in 1 ... 10 {
            let key = folder + "file" + String(fileIndex) + ".txt"
            keys.append(key)
            await uploadData(key: key, dataString: key)
        }

        let options = StorageListRequest.Options(accessLevel: .guest,
                                                 targetIdentityId: nil,
                                                 path: key1)
        let result = try await Amplify.Storage.list(options: options)
        let items = result.items
        
        XCTAssertEqual(items.count, keys.count)
        for item in items {
            XCTAssertTrue(keys.contains(item.key), "The key that was uploaded should match the key listed")
        }
        
        // Remove the keys
        for fileIndex in 1 ... 10 {
            let key = folder + "file" + String(fileIndex) + ".txt"
            keys.append(key)
            await remove(key: key)
        }
    }

    /// Given: An object in storage
    /// When: Call the remove API
    /// Then: The operation completes successfully with the key removed from storage
    func testRemoveKey() async throws {
        let key = UUID().uuidString
        await uploadData(key: key, dataString: key)

        let result = try await Amplify.Storage.remove(key: key, options: nil)
        XCTAssertEqual(result, key)
    }

    /// Given: Object with key `key` does not exist in storage
    /// When: Call the remove API
    /// Then: The operation completes successfully.
    func testRemoveNonExistentKey() async throws {
        let key = UUID().uuidString

        let result = try await Amplify.Storage.remove(key: key, options: nil)
        XCTAssertEqual(result, key)
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
}

private extension String {
    func md5() -> String {
        let digest = Insecure.MD5.hash(data: data(using: .utf8) ?? Data())
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
}
