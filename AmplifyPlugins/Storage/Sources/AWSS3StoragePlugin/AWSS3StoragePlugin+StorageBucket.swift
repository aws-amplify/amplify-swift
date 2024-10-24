//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(InternalAmplifyConfiguration) import Amplify
import Foundation

extension AWSS3StoragePlugin {
    /// Returns a AWSS3StorageServiceBehavior instance for the given StorageBucket
    func storageService(for bucket: (any StorageBucket)?) throws -> AWSS3StorageServiceBehavior {
        guard let bucket else {
            // When no bucket is provided, use the default one
            return defaultStorageService
        }

        let bucketInfo = try bucketInfo(from: bucket)
        guard let storageService = storageServicesByBucket[bucketInfo.bucketName] else {
            // If no service was found for the bucket, create one
            let storageService = try createStorageService(
                authService: authService,
                bucketInfo: bucketInfo
            )
            storageServicesByBucket[bucketInfo.bucketName] = storageService
            return storageService
        }

        return storageService
    }

    /// Returns a AWSS3StorageServiceProvider callback for the given StorageBucket
    func storageServiceProvider(for bucket: (any StorageBucket)?) -> AWSS3StorageServiceProvider {
        let storageServiceResolver: () throws -> AWSS3StorageServiceBehavior = { [weak self] in
            guard let self = self else {
                throw StorageError.unknown("AWSS3StoragePlugin was deallocated", nil)
            }
            return try self.storageService(for: bucket)
        }
        return storageServiceResolver
    }

    /// Returns a valid `BucketInfo` instance from the given StorageBucket
    private func bucketInfo(from bucket: any StorageBucket) throws -> BucketInfo {
        switch bucket {
        case let outputsBucket as OutputsStorageBucket:
            guard let additionalBucketsByName else {
                let errorDescription = "Amplify was not configured using an Amplify Outputs file"
                let recoverySuggestion = "Make sure that `Amplify.configure(with:)` is invoked"
                throw StorageError.validation("bucket", errorDescription, recoverySuggestion, nil)
            }

            guard let awsBucket = additionalBucketsByName[outputsBucket.name] else {
                let errorDescription = "Unable to lookup bucket from provided name in Amplify Outputs"
                let recoverySuggestion = "Make sure the bucket name exists in the Amplify Outputs file"
                throw StorageError.validation("bucket", errorDescription, recoverySuggestion, nil)
            }

            return .init(
                bucketName: awsBucket.bucketName,
                region: awsBucket.awsRegion
            )

        case let resolvedBucket as ResolvedStorageBucket:
            return resolvedBucket.bucketInfo

        default:
            let errorDescription = "The specified StorageBucket is not supported"
            let recoverySuggestion = "Please specify a StorageBucket from the Outputs file or from BucketInfo"
            throw StorageError.validation("bucket", errorDescription, recoverySuggestion, nil)
        }
    }
}
