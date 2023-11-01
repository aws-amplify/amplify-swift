//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import Amplify

//import AWSS3
//import ClientRuntime
//import AWSClientRuntime

/// The class conforming to AWSS3Behavior which uses an instance of the AWSS3 to perform its methods.
/// This class acts as a wrapper to expose AWSS3 functionality through an instance over a singleton,
/// and allows for mocking in unit tests. The methods contain no other logic other than calling the
/// same method using the AWSS3 instance.
class AWSS3Adapter: AWSS3Behavior {
    let awsS3: S3ClientProtocol
//    let config: S3Client.S3ClientConfiguration

    init(_ awsS3: S3ClientProtocol/*, config: S3Client.S3ClientConfiguration*/) {
        self.awsS3 = awsS3
//        self.config = config
    }

    /// Deletes object identify by request.
    /// - Parameters:
    ///   - request:: request identifying object
    ///   - completion: handle indicates when the operation is done
    func deleteObject(_ request: AWSS3DeleteObjectRequest) async throws {
        let input = DeleteObjectInput(bucket: request.bucket, key: request.key)
        _ = try await awsS3.deleteObject(input: input)
    }

    /// Lists objects in the bucket specified by `request`.
    /// - Parameters:
    ///   - request: request identifying bucket and options
    ///   - completion: handle which return a result with list of items
    func listObjectsV2(_ request: AWSS3ListObjectsV2Request) async throws -> StorageListResult {
        var finalPrefix: String?
        if let prefix = request.prefix {
            finalPrefix = prefix + (request.path ?? "")
        }
        let input = ListObjectsV2Input(
            bucket: request.bucket,
            continuationToken: request.continuationToken,
            delimiter: request.delimiter,
            maxKeys: request.maxKeys,
            prefix: finalPrefix,
            startAfter: request.startAfter
        )
        do {
            let response = try await awsS3.listObjectsV2(input: input)
            let contents: S3BucketContents = response.contents ?? []
            let items = try contents.map {
                try StorageListResult.Item(s3Object: $0, prefix: request.prefix ?? "")
            }
            let listResult = StorageListResult(items: items)
            return listResult
        } catch let error as StorageErrorConvertible {
            throw error.storageError
        } catch {
            throw StorageError(error: error)
        }

    }

    /// Creates a MultipartUpload
    /// - Parameters:
    ///   - request: request
    ///   - completion: handler which returns a result with uploadId
    func createMultipartUpload(_ request: CreateMultipartUploadRequest) async throws -> AWSS3CreateMultipartUploadResponse {
        let input = CreateMultipartUploadInput(
            key: request.key, bucket: request.bucket,
            cacheControl: request.cacheControl,
            contentDisposition: request.contentDisposition,
            contentEncoding: request.contentEncoding,
            contentLanguage: request.contentLanguage,
            contentType: request.contentType,
            expires: request.expires,
            metadata: request.metadata
        )

        do {
            let response = try await awsS3.createMultipartUpload(input: input)
            guard let bucket = response.bucket, let key = response.key, let uploadId = response.uploadId else {
                throw StorageError.unknown("Invalid response for creating multipart upload", nil)
            }
            return AWSS3CreateMultipartUploadResponse(bucket: bucket, key: key, uploadId: uploadId)
        } catch let error as StorageErrorConvertible {
            throw error.storageError
        } catch {
            throw StorageError(error: error)
        }
    }

    func listParts(bucket: String, key: String, uploadId: UploadID) async throws -> AWSS3ListUploadPartResponse {
        let input = ListPartsInput(bucket: bucket, key: key, uploadId: uploadId)
        do {
            let sdkResponse = try await awsS3.listParts(input: input)
            guard let response = AWSS3ListUploadPartResponse(response: sdkResponse) else {
                throw StorageError.unknown("ListParts response is invalid", nil)
            }
            return response
        } catch let error as StorageErrorConvertible {
            throw error.storageError
        } catch {
            throw StorageError(error: error)
        }
    }

    /// Completed a MultipartUpload
    /// - Parameters:
    ///   - request: request which includes uploadId
    ///   - completion: handler which returns a result with object details
    func completeMultipartUpload(_ request: AWSS3CompleteMultipartUploadRequest) async throws -> AWSS3CompleteMultipartUploadResponse {
        let parts = request.parts.map {
            S3ClientTypes.CompletedPart(eTag: $0.eTag, partNumber: $0.partNumber)
        }
        let completedMultipartUpload = S3ClientTypes.CompletedMultipartUpload(parts: parts)
        let input = CompleteMultipartUploadInput(
            bucket: request.bucket,
            key: request.key,
            uploadId: request.uploadId, 
            multipartUpload: completedMultipartUpload
        )
        do {
            let response = try await awsS3.completeMultipartUpload(input: input)
            guard let eTag = response.eTag else {
                throw StorageError.unknown("Invalid response for completing multipart upload", nil)
            }
            return AWSS3CompleteMultipartUploadResponse(bucket: request.bucket, key: request.key, eTag: eTag)

        } catch let error as StorageErrorConvertible {
            throw error.storageError
        } catch {
            throw StorageError(error: error)
        }
    }

    /// Aborts a MultipartUpload
    /// - Parameters:
    ///   - request: request which includes uploadId
    ///   - completion: handler which indicates when the operation is done
    func abortMultipartUpload(_ request: AWSS3AbortMultipartUploadRequest) async throws {
        let input = AbortMultipartUploadInput(bucket: request.bucket, uploadId: request.uploadId, key: request.key)
        do {
            _ = try await awsS3.abortMultipartUpload(input: input)
        } catch let error as StorageErrorConvertible {
            throw error.storageError
        } catch {
            throw StorageError(error: error)
        }
    }

    /// Instance of S3 service.
//    /// - Returns: S3 service instance.
//    func getS3() -> S3ClientProtocol {
//        return awsS3
//    }
}
