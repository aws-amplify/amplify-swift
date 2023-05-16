//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify

import AWSS3StoragePlugin
import ClientRuntime
import CryptoKit
import XCTest

class AWSS3StoragePluginBasicIntegrationTests: AWSS3StoragePluginTestBase {

    var uploadedKeys: [String]!

    /// Represents expected pieces of the User-Agent header of an SDK http request.
    ///
    /// Example SDK User-Agent:
    /// ```
    /// User-Agent: aws-sdk-swift/1.0 api/s3/1.0 os/iOS/16.4.0 lang/swift/5.8
    /// ```
    /// - Tag: SdkUserAgentComponent
    private enum SdkUserAgentComponent: String, CaseIterable {
        case api = "api/s3"
        case lang = "lang/swift"
        case os = "os/"
        case sdk = "aws-sdk-swift/"
    }

    /// Represents expected pieces of the User-Agent header of an URLRequest used for uploading or
    /// downloading.
    ///
    /// Example SDK User-Agent:
    /// ```
    /// User-Agent: lib/amplify-swift
    /// ```
    /// - Tag: SdkUserAgentComponent
    private enum URLUserAgentComponent: String, CaseIterable {
        case lib = "lib/amplify-swift"
        case os = "os/"
    }

    override func setUp() async throws {
        try await super.setUp()
        uploadedKeys = []
    }

    override func tearDown() async throws {
        for key in uploadedKeys {
            _ = try await Amplify.Storage.remove(key: key)
        }
        uploadedKeys = nil
        try await super.tearDown()
    }

    /// Given: An data object
    /// When: Upload the data
    /// Then: The operation completes successfully
    func testUploadData() async throws {
        let key = UUID().uuidString
        let data = key.data(using: .utf8)!

        _ = try await Amplify.Storage.uploadData(key: key, data: data, options: nil).value
        _ = try await Amplify.Storage.remove(key: key)

        // Only the remove operation results in an SDK request
        XCTAssertEqual(requestRecorder.sdkRequests.map { $0.method} , [.delete])
        try assertUserAgentComponents(sdkRequests: requestRecorder.sdkRequests)

        XCTAssertEqual(requestRecorder.urlRequests.map { $0.httpMethod }, ["PUT"])
        try assertUserAgentComponents(urlRequests: requestRecorder.urlRequests)
    }

    /// Given: A empty data object
    /// When: Upload the data
    /// Then: The operation completes successfully
    func testUploadEmptyData() async throws {
        let key = UUID().uuidString
        let data = "".data(using: .utf8)!
        _ = try await Amplify.Storage.uploadData(key: key, data: data, options: nil).value
        _ = try await Amplify.Storage.remove(key: key)

        XCTAssertEqual(requestRecorder.urlRequests.map { $0.httpMethod }, ["PUT"])
        try assertUserAgentComponents(urlRequests: requestRecorder.urlRequests)
    }

    /// Given: A file with contents
    /// When: Upload the file
    /// Then: The operation completes successfully and all URLSession and SDK requests include a user agent
    func testUploadFile() async throws {
        let key = UUID().uuidString
        let filePath = NSTemporaryDirectory() + key + ".tmp"

        let fileURL = URL(fileURLWithPath: filePath)
        FileManager.default.createFile(atPath: filePath, contents: key.data(using: .utf8), attributes: nil)

        _ = try await Amplify.Storage.uploadFile(key: key, local: fileURL, options: nil).value
        _ = try await Amplify.Storage.remove(key: key)

        // Only the remove operation results in an SDK request
        XCTAssertEqual(requestRecorder.sdkRequests.map { $0.method} , [.delete])
        try assertUserAgentComponents(sdkRequests: requestRecorder.sdkRequests)

        XCTAssertEqual(requestRecorder.urlRequests.map { $0.httpMethod }, ["PUT"])
        try assertUserAgentComponents(urlRequests: requestRecorder.urlRequests)
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
        _ = try await Amplify.Storage.remove(key: key)

        XCTAssertEqual(requestRecorder.urlRequests.map { $0.httpMethod }, ["PUT"])
        try assertUserAgentComponents(urlRequests: requestRecorder.urlRequests)
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

        let userAgents = requestRecorder.urlRequests.compactMap { $0.allHTTPHeaderFields?["User-Agent"] }
        XCTAssertGreaterThan(userAgents.count, 1)
        for userAgent in userAgents {
            let expectedComponent = "MultiPart/UploadPart"
            XCTAssertTrue(userAgent.contains(expectedComponent), "\(userAgent) does not contain \(expectedComponent)")
        }
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
        _ = try await Amplify.Storage.remove(key: key)

        let userAgents = requestRecorder.urlRequests.compactMap { $0.allHTTPHeaderFields?["User-Agent"] }
        XCTAssertGreaterThan(userAgents.count, 1)
        for userAgent in userAgents {
            let expectedComponent = "MultiPart/UploadPart"
            XCTAssertTrue(userAgent.contains(expectedComponent), "\(userAgent) does not contain \(expectedComponent)")
        }
    }

    /// Given: An object in storage
    /// When: Call the downloadData API
    /// Then: The operation completes successfully with the data retrieved
    func testDownloadDataToMemory() async throws {
        let key = UUID().uuidString
        await uploadData(key: key, data: key.data(using: .utf8)!)
        _ = try await Amplify.Storage.downloadData(key: key, options: .init()).value
        _ = try await Amplify.Storage.remove(key: key)
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
        _ = try await Amplify.Storage.remove(key: key)
    }

    /// Given: An object in storage
    /// When: Call the getURL API
    /// Then: The operation completes successfully with the URL retrieved
    func testGetRemoteURL() async throws {
        let key = UUID().uuidString
        await uploadData(key: key, dataString: key)

        let remoteURL = try await Amplify.Storage.getURL(key: key)

        // The presigned URL generation does not result in an SDK or HTTP call.
        XCTAssertEqual(requestRecorder.sdkRequests.map { $0.method} , [])

        let (data, response) = try await URLSession.shared.data(from: remoteURL)
        let httpResponse = try XCTUnwrap(response as? HTTPURLResponse)
        XCTAssertEqual(httpResponse.statusCode, 200)

        let dataString = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertEqual(dataString, key)

        _ = try await Amplify.Storage.remove(key: key)
    }

    /// - Given: A key for a non-existent S3 object
    /// - When: A pre-signed URL is requested for that key with `validateObjectExistence = true`
    /// - Then: A StorageError.keyNotFound error is thrown
    func testGetURLForUnknownKeyWithValidation() async throws {
        let unknownKey = UUID().uuidString
        do {
            let url = try await Amplify.Storage.getURL(
                key: unknownKey,
                options: .init(
                    pluginOptions: AWSStorageGetURLOptions(validateObjectExistence: true)
                )
            )
            XCTFail("Expecting failure but got url: \(url)")
        } catch StorageError.keyNotFound(let key, _, _, _) {
            XCTAssertTrue(key.contains(unknownKey))
        }

        // A S3 HeadObject call is expected
        XCTAssertEqual(requestRecorder.sdkRequests.map { $0.method} , [.head])
        try assertUserAgentComponents(sdkRequests: requestRecorder.sdkRequests)

        XCTAssertEqual(requestRecorder.urlRequests.map { $0.httpMethod }, [])
    }

    /// - Given: A key for a non-existent S3 object
    /// - When: A pre-signed URL is requested for that key with `validateObjectExistence = false`
    /// - Then: A pre-signed URL is returned
    func testGetURLForUnknownKeyWithoutValidation() async throws {
        let unknownKey = UUID().uuidString
        let url = try await Amplify.Storage.getURL(
            key: unknownKey,
            options: .init(
                pluginOptions: AWSStorageGetURLOptions(validateObjectExistence: false)
            )
        )
        XCTAssertNotNil(url)

        // No SDK or URLRequest calls expected
        XCTAssertEqual(requestRecorder.sdkRequests.map { $0.method} , [])
        XCTAssertEqual(requestRecorder.urlRequests.map { $0.httpMethod }, [])
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

        _ = try await Amplify.Storage.remove(key: key)

        // S3 GetObjectList and DeleteObject calls are expected
        XCTAssertEqual(requestRecorder.sdkRequests.map { $0.method}, [.get, .delete])
        try assertUserAgentComponents(sdkRequests: requestRecorder.sdkRequests)

        // A single URLRequest call is expected
        XCTAssertEqual(requestRecorder.urlRequests.map { $0.httpMethod }, ["PUT"])
    }

    /// Given: A collection of objects in storage numbering `objectCount`.
    /// When: The list API is invoked twice using a pageSize of `((objectCount/2) - 1)` and its
    ///      corresponding token options.
    /// Then: All objects are listed.
    func testListTwoPages() async throws {
        let objectCount = UInt.random(in: 16..<32)
        // One more than half in order to ensure there are only two pages
        let pageSize = UInt(objectCount/2) + 1
        let path = "pagination-\(UUID().uuidString)"
        for i in 0..<objectCount {
            let key = "\(path)/\(i).txt"
            let data = Data("\(i)".utf8)
            await uploadData(key: key, data: data)
            uploadedKeys.append(key)
        }

        // First half of listing
        let firstResult = try await Amplify.Storage.list(options: .init(
            accessLevel: .guest,
            path: path,
            pageSize: pageSize
        ))
        let firstPage = try XCTUnwrap(firstResult.items)
        XCTAssertEqual(firstPage.count, Int(pageSize))
        let firstNextToken = try XCTUnwrap(firstResult.nextToken)

        // Second half of listing
        let secondResult = try await Amplify.Storage.list(options: .init(
            accessLevel: .guest,
            path: path,
            pageSize: pageSize,
            nextToken: firstNextToken
        ))
        let secondPage = try XCTUnwrap(secondResult.items)
        XCTAssertEqual(secondPage.count, Int(objectCount - pageSize))
        XCTAssertNil(secondResult.nextToken)

        XCTAssertEqual(
            uploadedKeys.sorted(),
            Array((firstPage + secondPage).map { $0.key }).sorted()
        )

        // S3 GetObjectList calls are expected (DeleteObject calls happen during tearDown)
        XCTAssertEqual(requestRecorder.sdkRequests.map { $0.method}, [.get, .get])
        try assertUserAgentComponents(sdkRequests: requestRecorder.sdkRequests)

        // A URLRequest call for each uploaded file is expected
        let expectedURLRequestMethods: [String] = uploadedKeys.map { _ in "PUT" }
        XCTAssertEqual(requestRecorder.urlRequests.map { $0.httpMethod }, expectedURLRequestMethods)
        try assertUserAgentComponents(urlRequests: requestRecorder.urlRequests)
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

        // A single SDK call for the ListObjectsV2 request is expected
        XCTAssertEqual(requestRecorder.sdkRequests.map { $0.method}, [.get])
        try assertUserAgentComponents(sdkRequests: requestRecorder.sdkRequests)

        // No URLRequest calls expected
        XCTAssertEqual(requestRecorder.urlRequests.map { $0.httpMethod }, [])
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
        
        _ = try await Amplify.Storage.remove(key: key)

        XCTAssertEqual(requestRecorder.sdkRequests.map { $0.method}, [.get, .delete])
        try assertUserAgentComponents(sdkRequests: requestRecorder.sdkRequests)

        // A URLRequest call for each uploaded file is expected
        let expectedURLRequestMethods: [String] = keys.map { _ in "PUT" }
        XCTAssertEqual(requestRecorder.urlRequests.map { $0.httpMethod }, expectedURLRequestMethods)
        try assertUserAgentComponents(urlRequests: requestRecorder.urlRequests)
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
        
        for key in keys {
            _ = try await Amplify.Storage.remove(key: key)
        }

        // An SDK call for the ListObjectsV2 call and each deletion is expected
        let expectedMethods = [.get] + keys.map {_ in HttpMethodType.delete}
        XCTAssertEqual(requestRecorder.sdkRequests.map { $0.method}, expectedMethods)
        try assertUserAgentComponents(sdkRequests: requestRecorder.sdkRequests)

        // A URLRequest call for each uploaded file is expected
        let expectedURLRequestMethods: [String] = keys.map { _ in "PUT" }
        XCTAssertEqual(requestRecorder.urlRequests.map { $0.httpMethod }, expectedURLRequestMethods)
        try assertUserAgentComponents(urlRequests: requestRecorder.urlRequests)
    }

    /// Given: An object in storage
    /// When: Call the remove API
    /// Then: The operation completes successfully with the key removed from storage
    func testRemoveKey() async throws {
        let key = UUID().uuidString
        await uploadData(key: key, dataString: key)

        let result = try await Amplify.Storage.remove(key: key, options: nil)
        XCTAssertEqual(result, key)

        XCTAssertEqual(requestRecorder.sdkRequests.map { $0.method}, [.delete])
        try assertUserAgentComponents(sdkRequests: requestRecorder.sdkRequests)

        XCTAssertEqual(requestRecorder.urlRequests.map { $0.httpMethod }, ["PUT"])
        try assertUserAgentComponents(urlRequests: requestRecorder.urlRequests)
    }

    /// Given: Object with key `key` does not exist in storage
    /// When: Call the remove API
    /// Then: The operation completes successfully.
    func testRemoveNonExistentKey() async throws {
        let key = UUID().uuidString

        let result = try await Amplify.Storage.remove(key: key, options: nil)
        XCTAssertEqual(result, key)

        XCTAssertEqual(requestRecorder.sdkRequests.map { $0.method}, [.delete])
        try assertUserAgentComponents(sdkRequests: requestRecorder.sdkRequests)

        XCTAssertEqual(requestRecorder.urlRequests.map { $0.httpMethod }, [])
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

    private func assertUserAgentComponents(sdkRequests: [SdkHttpRequest], file: StaticString = #filePath, line: UInt = #line) throws {
        for request in sdkRequests {
            let headers = request.headers.dictionary
            let userAgent = try XCTUnwrap(headers["User-Agent"]?.joined(separator:","))
            for component in SdkUserAgentComponent.allCases {
                XCTAssertTrue(userAgent.contains(component.rawValue), "\(userAgent.description) does not contain \(component)", file: file, line: line)
            }
        }
    }

    private func assertUserAgentComponents(urlRequests: [URLRequest], file: StaticString = #filePath, line: UInt = #line) throws {
        for request in urlRequests {
            let headers = try XCTUnwrap(request.allHTTPHeaderFields)
            let userAgent = try XCTUnwrap(headers["User-Agent"])
            for component in URLUserAgentComponent.allCases {
                XCTAssertTrue(userAgent.contains(component.rawValue), "\(userAgent.description) does not contain \(component)", file: file, line: line)
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
