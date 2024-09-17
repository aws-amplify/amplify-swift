//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(InternalAmplifyConfiguration) @testable import Amplify
@testable import AWSS3StoragePlugin
import XCTest

class AWSS3StoragePluginMultipleBucketTests: AWSS3StoragePluginTestBase {
    private var customBucket: ResolvedStorageBucket!

    override func setUp() async throws {
        guard let outputs = try? AmplifyOutputs.amplifyOutputs.resolveConfiguration(),
              let additionalBucket = outputs.storage?.buckets?.first else {
            throw XCTSkip("Multibucket has not been configured. Skipping test")
        }
        customBucket = .fromBucketInfo(.init(
            bucketName: additionalBucket.bucketName,
            region: additionalBucket.awsRegion
        ))
        try await super.setUp()
    }

    override func tearDown() async throws {
        try await Task.sleep(seconds: 0.1)
        try await super.tearDown()
    }

    /// Given: An data object
    /// When: Upload the data to a custom buckets using keys
    /// Then: The operation completes successfully
    func testUploadData_toCustomBucket_usingKey_shouldSucceed() async throws {
        let key = UUID().uuidString
        let data = Data(key.utf8)

        let uploaded = try await Amplify.Storage.uploadData(
            key: key,
            data: data,
            options: .init(bucket: customBucket)
        ).value
        XCTAssertEqual(uploaded, key)

        let deleted = try await Amplify.Storage.remove(
            key: key,
            options: .init(bucket: customBucket)
        )
        XCTAssertEqual(deleted, key)
    }

    /// Given: An data object
    /// When: Upload the data to a custom bucket using StoragePath
    /// Then: The operation completes successfully
    func testUploadData_toCustomBucket_usingStoragePath_shouldSucceed() async throws {
        let id = UUID().uuidString
        let data = Data(id.utf8)
        let path: StringStoragePath = .fromString("public/\(id)")

        let uploaded = try await Amplify.Storage.uploadData(
            path: path,
            data: data,
            options: .init(bucket: customBucket)
        ).value
        XCTAssertEqual(uploaded, path.string)

        let deleted = try await Amplify.Storage.remove(
            path: path,
            options: .init(bucket: customBucket)
        )
        XCTAssertEqual(deleted, path.string)
    }

    /// Given: A file with contents
    /// When: Upload the file to a custom bucket using key
    /// Then: The operation completes successfully and all URLSession and SDK requests include a user agent
    func testUploadFile_toCustomBucket_usingKey_shouldSucceed() async throws {
        let key = UUID().uuidString
        let filePath = NSTemporaryDirectory() + key + ".tmp"

        let fileURL = URL(fileURLWithPath: filePath)
        FileManager.default.createFile(atPath: filePath, contents: Data(key.utf8), attributes: nil)

        let uploaded = try await Amplify.Storage.uploadFile(
            key: key,
            local: fileURL,
            options: .init(bucket: customBucket)
        ).value
        XCTAssertEqual(uploaded, key)

        let deleted = try await Amplify.Storage.remove(
            key: key,
            options: .init(bucket: customBucket)
        )
        XCTAssertEqual(deleted, key)
    }

    /// Given: A file with contents
    /// When: Upload the file to a custom bucket using StoragePath
    /// Then: The operation completes successfully and all URLSession and SDK requests include a user agent
    func testUploadFile_toCustomBucket_usingStoragePath_shouldSucceed() async throws {
        let id = UUID().uuidString
        let filePath = NSTemporaryDirectory() + id + ".tmp"
        let path: StringStoragePath = .fromString("public/\(id)")

        let fileURL = URL(fileURLWithPath: filePath)
        FileManager.default.createFile(atPath: filePath, contents: Data(id.utf8), attributes: nil)

        let uploaded = try await Amplify.Storage.uploadFile(
            path: path,
            local: fileURL,
            options: .init(bucket: customBucket)
        ).value
        XCTAssertEqual(uploaded, path.string)

        let deleted = try await Amplify.Storage.remove(
            path: path,
            options: .init(bucket: customBucket)
        )
        XCTAssertEqual(deleted, path.string)
    }

    /// Given: A large  data object
    /// When: Upload the data to a custom bucket using key
    /// Then: The operation completes successfully
    func testUploadLargeData_toCustomBucket_usingKey_shouldSucceed() async throws {
        let key = UUID().uuidString

        let uploaded = try await Amplify.Storage.uploadData(
            key: key,
            data: AWSS3StoragePluginTestBase.largeDataObject,
            options: .init(bucket: customBucket)
        ).value
        XCTAssertEqual(uploaded, key)

        let deleted = try await Amplify.Storage.remove(
            key: key,
            options: .init(bucket: customBucket)
        )
        XCTAssertEqual(deleted, key)
    }

    /// Given: A large  data object
    /// When: Upload the data to a custom bucket using StoragePath
    /// Then: The operation completes successfully
    func testUploadLargeData_toCustomBucket_usingStoragePath_shouldSucceed() async throws {
        let id = UUID().uuidString
        let path: StringStoragePath = .fromString("public/\(id)")

        let uploaded = try await Amplify.Storage.uploadData(
            path: path,
            data: AWSS3StoragePluginTestBase.largeDataObject,
            options: .init(bucket: customBucket)
        ).value
        XCTAssertEqual(uploaded, path.string)

        let deleted = try await Amplify.Storage.remove(
            path: path,
            options: .init(bucket: customBucket)
        )
        XCTAssertEqual(deleted, path.string)
    }

    /// Given: A large file
    /// When: Upload the file to a custom bucket using key
    /// Then: The operation completes successfully
    func testUploadLargeFile_toCustomBucket_usingKey_shouldSucceed() async throws {
        let key = UUID().uuidString
        let filePath = NSTemporaryDirectory() + key + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)

        FileManager.default.createFile(
            atPath: filePath,
            contents: AWSS3StoragePluginTestBase.largeDataObject,
            attributes: nil
        )

        let uploaded = try await Amplify.Storage.uploadFile(
            key: key,
            local: fileURL,
            options: .init(bucket: customBucket)
        ).value
        XCTAssertEqual(uploaded, key)


        let deleted = try await Amplify.Storage.remove(
            key: key,
            options: .init(bucket: customBucket)
        )
        XCTAssertEqual(deleted, key)
    }

    /// Given: A large file
    /// When: Upload the file to a custom bucket using key
    /// Then: The operation completes successfully
    func testUploadLargeFile_toCustomBucket_usingStoragePath_shouldSucceed() async throws {
        let id = UUID().uuidString
        let filePath = NSTemporaryDirectory() + id + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)
        let path: StringStoragePath = .fromString("public/\(id)")

        FileManager.default.createFile(
            atPath: filePath,
            contents: AWSS3StoragePluginTestBase.largeDataObject,
            attributes: nil
        )

        let uploaded = try await Amplify.Storage.uploadFile(
            path: path,
            local: fileURL,
            options: .init(bucket: customBucket)
        ).value
        XCTAssertEqual(uploaded, path.string)


        let deleted = try await Amplify.Storage.remove(
            path: path,
            options: .init(bucket: customBucket)
        )
        XCTAssertEqual(deleted, path.string)
    }

    /// Given: An object in storage in a custom bucket
    /// When: Call the downloadData API using key
    /// Then: The operation completes successfully with the data retrieved
    func testDownloadData_fromCustomBucket_usingKey_shouldSucceed() async throws {
        let key = UUID().uuidString
        let data = Data(key.utf8)
        try await uploadData(
            key: key, 
            data: data,
            options: .init(bucket: customBucket)
        )

        let downloaded = try await Amplify.Storage.downloadData(
            key: key,
            options: .init(bucket: customBucket)
        ).value
        XCTAssertEqual(data.count, downloaded.count)

        let deleted = try await Amplify.Storage.remove(
            key: key,
            options: .init(bucket: customBucket)
        )
        XCTAssertEqual(deleted, key)
    }

    /// Given: An object in storage in a custom bucket
    /// When: Call the downloadData API using StoragePath
    /// Then: The operation completes successfully with the data retrieved
    func testDownloadData_fromCustomBucket_usingStoragePath_shouldSucceed() async throws {
        let id = UUID().uuidString
        let data = Data(id.utf8)
        let path: StringStoragePath = .fromString("public/\(id)")
        try await uploadData(
            path: path,
            data: data,
            options: .init(bucket: customBucket)
        )

        let downloaded = try await Amplify.Storage.downloadData(
            path: path,
            options: .init(bucket: customBucket)
        ).value
        XCTAssertEqual(data.count, downloaded.count)

        let deleted = try await Amplify.Storage.remove(
            path: path,
            options: .init(bucket: customBucket)
        )
        XCTAssertEqual(deleted, path.string)
    }

    /// Given: An object in storage in a custom bucket
    /// When: Call the downloadFile API using key
    /// Then: The operation completes successfully the local file containing the data from the object
    func testDownloadFile_fromCustomBucket_usingKey_shouldSucceed() async throws {
        let key = UUID().uuidString
        let timestamp = String(Date().timeIntervalSince1970)
        let timestampData = Data(timestamp.utf8)
        try await uploadData(
            key: key,
            data: timestampData,
            options: .init(bucket: customBucket)
        )
        let filePath = NSTemporaryDirectory() + key + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)
        removeFileIfExisting(fileURL)

        try await Amplify.Storage.downloadFile(
            key: key,
            local: fileURL,
            options: .init(bucket: customBucket)
        ).value

        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        do {
            let result = try String(contentsOf: fileURL, encoding: .utf8)
            XCTAssertEqual(result, timestamp)
        } catch {
            XCTFail("Failed to read downloaded file")
        }
        
        removeFileIfExisting(fileURL)
        let deleted = try await Amplify.Storage.remove(
            key: key,
            options: .init(bucket: customBucket)
        )
        XCTAssertEqual(deleted, key)
    }

    /// Given: An object in storage in a custom bucket
    /// When: Call the downloadFile API using StoragePath
    /// Then: The operation completes successfully the local file containing the data from the object
    func testDownloadFile_fromCustomBucket_usingStoragePath_shouldSucceed() async throws {
        let id = UUID().uuidString
        let timestamp = String(Date().timeIntervalSince1970)
        let timestampData = Data(timestamp.utf8)
        let path: StringStoragePath = .fromString("public/\(id)")
        try await uploadData(
            path: path,
            data: timestampData,
            options: .init(bucket: customBucket)
        )
        let filePath = NSTemporaryDirectory() + id + ".tmp"
        let fileURL = URL(fileURLWithPath: filePath)
        removeFileIfExisting(fileURL)

        try await Amplify.Storage.downloadFile(
            path: path,
            local: fileURL,
            options: .init(bucket: customBucket)
        ).value

        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        do {
            let result = try String(contentsOf: fileURL, encoding: .utf8)
            XCTAssertEqual(result, timestamp)
        } catch {
            XCTFail("Failed to read downloaded file")
        }

        removeFileIfExisting(fileURL)
        let deleted = try await Amplify.Storage.remove(
            path: path,
            options: .init(bucket: customBucket)
        )
        XCTAssertEqual(deleted, path.string)
    }

    /// Given: An object in storage in a custom bucket
    /// When: Call the getURL API using key
    /// Then: The operation completes successfully with the URL retrieved
    func testGetRemoteURL_fromCustomBucket_usingKey_shouldSucceed() async throws {
        let key = UUID().uuidString
        try await uploadData(
            key: key,
            data: Data(key.utf8),
            options: .init(bucket: customBucket)
        )

        let remoteURL = try await Amplify.Storage.getURL(
            key: key,
            options: .init(bucket: customBucket)
        )

        let (data, response) = try await URLSession.shared.data(from: remoteURL)
        let httpResponse = try XCTUnwrap(response as? HTTPURLResponse)
        XCTAssertEqual(httpResponse.statusCode, 200)

        let dataString = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertEqual(dataString, key)

        let deleted = try await Amplify.Storage.remove(
            key: key,
            options: .init(bucket: customBucket)
        )
        XCTAssertEqual(deleted, key)
    }

    /// Given: An object in storage in a custom bucket
    /// When: Call the getURL API using StoragePath
    /// Then: The operation completes successfully with the URL retrieved
    func testGetRemoteURL_fromCustomBucket_usingStoragePath_shouldSucceed() async throws {
        let id = UUID().uuidString
        let path: StringStoragePath = .fromString("public/\(id)")
        try await uploadData(
            path: path,
            data: Data(id.utf8),
            options: .init(bucket: customBucket)
        )

        let remoteURL = try await Amplify.Storage.getURL(
            path: path,
            options: .init(bucket: customBucket)
        )

        let (data, response) = try await URLSession.shared.data(from: remoteURL)
        let httpResponse = try XCTUnwrap(response as? HTTPURLResponse)
        XCTAssertEqual(httpResponse.statusCode, 200)

        let dataString = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertEqual(dataString, id)

        let deleted = try await Amplify.Storage.remove(
            path: path,
            options: .init(bucket: customBucket)
        )
        XCTAssertEqual(deleted, path.string)
    }

    /// Given: An object in storage in a custom bucket
    /// When: Call the list API using StoragePath
    /// Then: The operation completes successfully with the key retrieved
    func testList_fromOtherBucket_usingStoragePath_shouldSucceed() async throws {
        let id = UUID().uuidString
        let path: StringStoragePath = .fromString("public/\(id)")
        try await uploadData(
            path: path,
            data: Data(id.utf8),
            options: .init(bucket: customBucket)
        )

        let result = try await Amplify.Storage.list(
            path: path,
            options: .init(bucket: customBucket)
        )
        let items = try XCTUnwrap(result.items)

        XCTAssertEqual(items.count, 1)
        let item = try XCTUnwrap(items.first)
        XCTAssertEqual(item.path, path.string)
        XCTAssertNotNil(item.eTag)
        XCTAssertNotNil(item.lastModified)
        XCTAssertNotNil(item.size)

        let deleted = try await Amplify.Storage.remove(
            path: path,
            options: .init(bucket: customBucket)
        )
        XCTAssertEqual(deleted, path.string)
    }

    /// Given: An object in storage  in a custom bucket
    /// When: Call the remove API using key
    /// Then: The operation completes successfully with the key removed from storage
    func testRemoveKey_fromCustomBucket_usingKey_shouldSucceed() async throws {
        let key = UUID().uuidString
        try await uploadData(
            key: key,
            data: Data(key.utf8),
            options: .init(bucket: customBucket)
        )

        let deleted = try await Amplify.Storage.remove(
            key: key,
            options: .init(bucket: customBucket)
        )
        XCTAssertEqual(deleted, key)
    }

    /// Given: An object in storage  in a custom bucket
    /// When: Call the remove API using StoragePath
    /// Then: The operation completes successfully with the key removed from storage
    func testRemoveKey_fromCustomBucket_usingStoragePath_shouldSucceed() async throws {
        let id = UUID().uuidString
        let path: StringStoragePath = .fromString("public/\(id)")
        try await uploadData(
            path: path,
            data: Data(id.utf8),
            options: .init(bucket: customBucket)
        )

        let deleted = try await Amplify.Storage.remove(
            path: path,
            options: .init(bucket: customBucket)
        )
        XCTAssertEqual(deleted, path.string)
    }

    private func removeFileIfExisting(_ fileURL: URL) {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return
        }
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            XCTFail("Failed to remove file at \(fileURL)")
        }
    }
}

private extension StringStoragePath {
    var string: String {
        return resolve("")
    }
}
