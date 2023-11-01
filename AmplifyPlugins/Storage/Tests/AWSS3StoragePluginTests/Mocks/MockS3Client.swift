//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import AWSS3StoragePlugin

/// - Tag: MockS3Client
final class MockS3Client {

    /// - Tag: MockS3ClientClientError
    enum ClientError: Error {
        case missingImplementation
        case missingResult
    }

    /// - Tag: MockS3Client.interactions
    var interactions: [String] = []

    /// Used by [MockS3Client.listObjectsV2](x-source-tag://MockS3Client.listObjectsV2)
    /// in order to extract results during each invocation.
    ///
    /// - Tag: MockS3Client.listObjectsV2Handler
    var listObjectsV2Handler: (ListObjectsV2Input) async throws -> ListObjectsV2OutputResponse = { _ in throw ClientError.missingResult }

    var headObjectHandler: (HeadObjectInput) async throws -> HeadObjectOutputResponse = { _ in return HeadObjectOutputResponse() }
}

extension MockS3Client: S3ClientProtocol {
    func deleteObject(input: DeleteObjectInput) async throws -> DeleteObjectOutputResponse {
        fatalError()
    }

    func createMultipartUpload(input: CreateMultipartUploadInput) async throws -> CreateMultipartUploadOutputResponse {
        fatalError()
    }

    func listParts(input: ListPartsInput) async throws -> ListPartsOutputResponse {
        fatalError()
    }

    func completeMultipartUpload(input: CompleteMultipartUploadInput) async throws -> CompleteMultipartUploadOutputResponse {
        fatalError()
    }

    func abortMultipartUpload(input: AbortMultipartUploadInput) async throws -> AbortMultipartUploadOutputResponse {
        fatalError()
    }

    func headObject(input: HeadObjectInput) async throws -> HeadObjectOutputResponse {
        fatalError()
    }


    /// - Tag: MockS3Client.listObjectsV2
    func listObjectsV2(input: ListObjectsV2Input) async throws -> ListObjectsV2OutputResponse {
        interactions.append("\(#function) bucket: \(input.bucket) prefix: \(input.prefix ?? "nil") continuationToken: \(input.continuationToken ?? "nil")")
        return try await listObjectsV2Handler(input)
    }
}
