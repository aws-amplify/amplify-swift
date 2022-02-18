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

    init(_ awsS3: S3Client) {
        self.awsS3 = awsS3
    }

    /// Deletes object identify by request.
    /// - Parameter request: request identifying object
    /// - Returns: task
    public func deleteObject(_ request: AWSS3DeleteObjectRequest, completion: @escaping (Result<Void, StorageError>) -> Void) {
        let input = DeleteObjectInput(bucket: request.bucket, key: request.key)
        awsS3.deleteObject(input: input) { result in
            switch(result) {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error.storageError))
            }
        }
    }

    /// Lists objects in the bucket specified by `request`.
    /// - Parameter request: request identifying bucket and options
    /// - Returns: task
    public func listObjectsV2(_ request: AWSS3ListObjectsV2Request, completion: @escaping (Result<StorageListResult, StorageError>) -> Void) {
        let input = ListObjectsV2Input(prefix: request.prefix,
                                       bucket: request.bucket,
                                       continuationToken: request.continuationToken,
                                       delimiter: request.delimiter,
                                       maxKeys: request.maxKeys,
                                       startAfter: request.startAfter)
        awsS3.listObjectsV2(input: input) { result in
            switch(result) {
            case .success(let response):
                let contents: S3BucketContents = response.contents ?? []
                do {
                    let items = try contents.map {
                        try StorageListResult.Item(s3Object: $0, prefix: request.prefix ?? "")
                    }
                    let listResult = StorageListResult(items: items)
                    completion(.success(listResult))
                } catch {
                    completion(.failure(StorageError(error: error)))
                }
            case .failure(let error):
                completion(.failure(error.storageError))
            }
        }
    }

    /// Instance of S3 service.
    /// - Returns: S3 service instance.
    public func getS3() -> S3Client {
        return awsS3
    }
}

