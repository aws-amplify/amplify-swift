//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import AWSPluginsCore
import AWSS3StoragePlugin
import AWSS3

class AWSS3StoragePluginUploadMetadataTestCase: AWSS3StoragePluginTestBase {
    // MARK: - Tests

    /// Given: `StorageUploadFileRequest.Options` with `metadata`
    /// When: Uploading a file below the MPU threshold.
    /// Then:  That object's headers (retrieved via `HeadObject`) should contain the passed`metadata`
    func test_uploadSmallFileWithMetadata_headContainsMetadata() async throws {
        // Include metadata in upload file request
        let (mdKey, mdValue) = ("upload-small-file-with-metadata", UUID().uuidString)
        let options = StorageUploadFileRequest.Options(
            metadata: [mdKey: mdValue]
        )

        // upload file
        let key = UUID().uuidString
        let fileURL = temporaryFile(named: key, data: data(mb: 1))
        _ = try await Amplify.Storage.uploadFile(
            key: key,
            local: fileURL,
            options: options
        ).value

        // call `HeadObject` through SDK escape hatch
        let head = try await headObject(key: "public/\(key)")

        // the `HeadObject` response should contain metadata
        // with the key-value pair including in the upload
        XCTAssertEqual(
            head.metadata?[mdKey],
            mdValue,
            """
            Expected `headObject().metadata` to contain key-value
            pair - \(mdKey): \(mdKey)
            Instead, received metadata is \(head.metadata as Any)
            """
        )

        // clean up
        _ = try await Amplify.Storage.remove(key: key)
    }

    /// Given: `StorageUploadFileRequest.Options` with `metadata`
    /// When: Uploading a file above the MPU threshold.
    /// Then:  That object's headers (retrieved via `HeadObject`) should contain the passed`metadata`
    func test_uploadLargeFileWithMetadata_headContainsMetadata() async throws {
        // Include metadata in upload file request
        let (mdKey, mdValue) = ("upload-large-file-with-metadata", UUID().uuidString)
        let options = StorageUploadFileRequest.Options(
            metadata: [mdKey: mdValue]
        )

        // upload file
        let key = UUID().uuidString
        let fileURL = temporaryFile(named: key, data: data(mb: 7))
        _ = try await Amplify.Storage.uploadFile(
            key: key,
            local: fileURL,
            options: options
        ).value

        // call `HeadObject` through SDK escape hatch
        let head = try await headObject(key: "public/\(key)")

        // the `HeadObject` response should contain metadata
        // with the key-value pair including in the upload
        XCTAssertEqual(
            head.metadata?[mdKey],
            mdValue,
            """
            Expected `headObject().metadata` to contain key-value
            pair - \(mdKey): \(mdKey)
            Instead, received metadata is \(head.metadata as Any)
            """
        )

        // clean up
        _ = try await Amplify.Storage.remove(key: key)
    }

    /// Given: `StorageUploadDataRequest.Options` with `metadata`
    /// When: Uploading data with a size below the MPU threshold.
    /// Then:  That object's headers (retrieved via `HeadObject`) should contain the passed`metadata`
    func test_uploadSmallDataWithMetadata_headContainsMetadata() async throws {
        // Include metadata in upload file request
        let (mdKey, mdValue) = ("upload-small-data-with-metadata", UUID().uuidString)
        let options = StorageUploadDataRequest.Options(
            metadata: [mdKey: mdValue]
        )

        // upload file
        let key = UUID().uuidString
        _ = try await Amplify.Storage.uploadData(
            key: key,
            data: data(mb: 1),
            options: options
        ).value

        // call `HeadObject` through SDK escape hatch
        let head = try await headObject(key: "public/\(key)")

        // the `HeadObject` response should contain metadata
        // with the key-value pair including in the upload
        XCTAssertEqual(
            head.metadata?[mdKey],
            mdValue,
            """
            Expected `headObject().metadata` to contain key-value
            pair - \(mdKey): \(mdKey)
            Instead, received metadata is \(head.metadata as Any)
            """
        )

        // clean up
        _ = try await Amplify.Storage.remove(key: key)
    }

    /// Given: `StorageUploadDataRequest.Options` with `metadata`
    /// When: Uploading data with a size below the MPU threshold.
    /// Then:  That object's headers (retrieved via `HeadObject`) should contain the passed`metadata`
    func test_uploadLargeDataWithMetadata_headContainsMetadata() async throws {
        // Include metadata in upload file request
        let (mdKey, mdValue) = ("upload-large-data-with-metadata", UUID().uuidString)
        let options = StorageUploadDataRequest.Options(
            metadata: [mdKey: mdValue]
        )

        // upload file
        let key = UUID().uuidString
        _ = try await Amplify.Storage.uploadData(
            key: key,
            data: data(mb: 7),
            options: options
        ).value

        // call `HeadObject` through SDK escape hatch
        let head = try await headObject(key: "public/\(key)")

        // the `HeadObject` response should contain metadata
        // with the key-value pair including in the upload
        XCTAssertEqual(
            head.metadata?[mdKey],
            mdValue,
            """
            Expected `headObject().metadata` to contain key-value
            pair - \(mdKey): \(mdKey)
            Instead, received metadata is \(head.metadata as Any)
            """
        )

        // clean up
        _ = try await Amplify.Storage.remove(key: key)
    }

    /// Given: `StorageUploadDataRequest.Options` with multiple
    /// `metadata` key-value pairs.
    /// When: Calling uploading an object via `uploadData`
    /// Then:  That object's headers (retrieved via `HeadObject`) should contain
    /// all key-value pairs`metadata`
    func test_uploadWithMultipleMetadataPairs() async throws {
        // Include metadata in upload file request
        let range = (1...11)
        let metadata = zip(range, range.dropFirst())
            .map { tuple -> (String, String) in
                (.init(tuple.0), .init(tuple.0))
            }
            .reduce(into: [String: String]()) { dict, pair in
                let (key, value) = pair
                dict[key] = value
            }

        let options = StorageUploadDataRequest.Options(
            metadata: metadata
        )

        // upload file
        let key = UUID().uuidString
        _ = try await Amplify.Storage.uploadData(
            key: key,
            data: data(mb: 1),
            options: options
        ).value

        // call `HeadObject` through SDK escape hatch
        let head = try await headObject(key: "public/\(key)")

        // the `HeadObject` response should contain metadata
        // with the key-value pair including in the upload
        XCTAssertEqual(
            head.metadata,
            metadata,
            """
            Expected `headObject().metadata` to equal
            user-defined metadata \(metadata).
            Instead, received metadata: \(head.metadata as Any)
            """
        )

        // clean up
        _ = try await Amplify.Storage.remove(key: key)
    }

    // MARK: - Helper Functions
    private func data(mb: Int) -> Data {
        Data(
            repeating: 0xff,
            count: 1_024 * 1_024 * mb
        )
    }

    private func temporaryFile(named key: String, data: Data) -> URL {
        let filePath = "\(NSTemporaryDirectory() + key).tmp"
        let fileURL = URL(fileURLWithPath: filePath)
        FileManager.default.createFile(
            atPath: filePath,
            contents: data,
            attributes: nil
        )
        return fileURL
    }

    private func headObject(key: String) async throws -> HeadObjectOutput {
        let plugin = try Amplify.Storage.getPlugin(for: "awsS3StoragePlugin")
        let storagePlugin = try XCTUnwrap(
            plugin as? AWSS3StoragePlugin,
            "Cast to `AWSS3StoragePlugin` failed"
        )
        let s3Client = storagePlugin.getEscapeHatch()
        let bucket = try AWSS3StoragePluginTestBase.getBucketFromConfig(
            forResource: "amplifyconfiguration"
        )
        let input = HeadObjectInput(
            bucket: bucket,
            key: key
        )

        return try await s3Client.headObject(input: input)
    }
}


