//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import Amplify

import AWSS3
import ClientRuntime
import AWSClientRuntime

/// The class conforming to AWSS3Behavior which uses an instance of the AWSS3 to perform its methods.
/// This class acts as a wrapper to expose AWSS3 functionality through an instance over a singleton,
/// and allows for mocking in unit tests. The methods contain no other logic other than calling the
/// same method using the AWSS3 instance.
class AWSS3Adapter: AWSS3Behavior {
    let awsS3: S3Client
    let config: AWSClientRuntime.AWSClientConfiguration

    init(_ awsS3: S3Client, config: AWSClientRuntime.AWSClientConfiguration) {
        self.awsS3 = awsS3
        self.config = config
    }

    /// Deletes object identify by request.
    /// - Parameters:
    ///   - request:: request identifying object
    ///   - completion: handle indicates when the operation is done
    func deleteObject(_ request: AWSS3DeleteObjectRequest, completion: @escaping (Result<Void, StorageError>) -> Void) {
        Task {
            let input = DeleteObjectInput(bucket: request.bucket, key: request.key)
            do {
                _ = try await awsS3.deleteObject(input: input)
                completion(.success(()))
            } catch {
                completion(.failure(StorageError(error: error)))
            }
        }
    }

    /// Lists objects in the bucket specified by `request`.
    /// - Parameters:
    ///   - request: request identifying bucket and options
    ///   - completion: handle which return a result with list of items
    func listObjectsV2(_ request: AWSS3ListObjectsV2Request, completion: @escaping (Result<StorageListResult, StorageError>) -> Void) {
        Task {
            let input = ListObjectsV2Input(bucket: request.bucket,
                                           continuationToken: request.continuationToken,
                                           delimiter: request.delimiter,
                                           maxKeys: request.maxKeys,
                                           prefix: request.prefix,
                                           startAfter: request.startAfter)
            do {
                let response = try await awsS3.listObjectsV2(input: input)
                let contents: S3BucketContents = response.contents ?? []
                let items = try contents.map {
                    try StorageListResult.Item(s3Object: $0, prefix: request.prefix ?? "")
                }
                let listResult = StorageListResult(items: items)
                completion(.success(listResult))
            } catch {
                completion(.failure(StorageError(error: error)))
            }
        }
    }

    /// Creates a MultipartUpload
    /// - Parameters:
    ///   - request: request
    ///   - completion: handler which returns a result with uploadId
    func createMultipartUpload(_ request: CreateMultipartUploadRequest, completion: @escaping (Result<AWSS3CreateMultipartUploadResponse, StorageError>) -> Void) {
        Task {
            let input = CreateMultipartUploadInput(bucket: request.bucket,
                                                   cacheControl: request.cacheControl,
                                                   contentDisposition: request.contentDisposition,
                                                   contentEncoding: request.contentEncoding,
                                                   contentLanguage: request.contentLanguage,
                                                   contentType: request.contentType,
                                                   expires: request.expires,
                                                   key: request.key,
                                                   metadata: request.metadata)

            do {
                let response = try await awsS3.createMultipartUpload(input: input)
                guard let bucket = response.bucket, let key = response.key, let uploadId = response.uploadId else {
                    completion(.failure(StorageError.unknown("Invalid response for creating multipart upload", nil)))
                    return
                }
                completion(.success(AWSS3CreateMultipartUploadResponse(bucket: bucket, key: key, uploadId: uploadId)))
            } catch {
                completion(.failure(StorageError(error: error)))
            }
        }
    }

    func listParts(bucket: String, key: String, uploadId: UploadID, completion: @escaping (Result<AWSS3ListUploadPartResponse, StorageError>) -> Void) {
        Task {
            let input = ListPartsInput(bucket: bucket, key: key, uploadId: uploadId)
            do {
                let sdkResponse = try await awsS3.listParts(input: input)
                guard let response = AWSS3ListUploadPartResponse(response: sdkResponse) else {
                    completion(.failure(StorageError.unknown("ListParts response is invalid", nil)))
                    return
                }
                completion(.success(response))
            } catch {
                completion(.failure(StorageError(error: error)))
            }
        }
    }

    /// Completed a MultipartUpload
    /// - Parameters:
    ///   - request: request which includes uploadId
    ///   - completion: handler which returns a result with object details
    func completeMultipartUpload(_ request: AWSS3CompleteMultipartUploadRequest, completion: @escaping (Result<AWSS3CompleteMultipartUploadResponse, StorageError>) -> Void) {
        Task {
            let parts = request.parts.map {
                S3ClientTypes.CompletedPart(eTag: $0.eTag, partNumber: $0.partNumber)
            }
            let completedMultipartUpload = S3ClientTypes.CompletedMultipartUpload(parts: parts)
            let input = CompleteMultipartUploadInput(bucket: request.bucket, key: request.key, multipartUpload: completedMultipartUpload, uploadId: request.uploadId)
            do {
                let response = try await awsS3.completeMultipartUpload(input: input)
                guard let eTag = response.eTag else {
                    completion(.failure(StorageError.unknown("Invalid response for completing multipart upload", nil)))
                    return
                }
                completion(.success(AWSS3CompleteMultipartUploadResponse(bucket: request.bucket, key: request.key, eTag: eTag)))
            } catch {
                completion(.failure(StorageError(error: error)))
            }
        }
    }

    /// Aborts a MultipartUpload
    /// - Parameters:
    ///   - request: request which includes uploadId
    ///   - completion: handler which indicates when the operation is done
    func abortMultipartUpload(_ request: AWSS3AbortMultipartUploadRequest, completion: @escaping (Result<Void, StorageError>) -> Void) {
        Task {
            let input = AbortMultipartUploadInput(bucket: request.bucket, key: request.key, uploadId: request.uploadId)
            do {
                _ = try await awsS3.abortMultipartUpload(input: input)
                completion(.success(()))
            } catch {
                completion(.failure(StorageError(error: error)))
            }
        }
    }

    /// Instance of S3 service.
    /// - Returns: S3 service instance.
    func getS3() -> S3Client {
        return awsS3
    }
}
