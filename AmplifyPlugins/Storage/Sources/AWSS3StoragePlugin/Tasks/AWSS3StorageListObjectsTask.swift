//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSS3
import AWSPluginsCore

protocol StorageListObjectsTask: AmplifyTaskExecution where Request == StorageListRequest, Success == StorageListResult, Failure == StorageError {}

class AWSS3StorageListObjectsTask: StorageListObjectsTask, DefaultLogger {

    let request: StorageListRequest
    let storageConfiguration: AWSS3StoragePluginConfiguration
    let storageBehaviour: AWSS3StorageServiceBehavior

    init(_ request: StorageListRequest,
         storageConfiguration: AWSS3StoragePluginConfiguration,
         storageBehaviour: AWSS3StorageServiceBehavior) {
        self.request = request
        self.storageConfiguration = storageConfiguration
        self.storageBehaviour = storageBehaviour
    }

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Storage.list
    }

    var eventNameCategoryType: CategoryType {
        .storage
    }

    func execute() async throws -> StorageListResult {
        guard let path = try await request.path?.resolvePath() else {
            throw StorageError.validation(
                "path",
                "`path` is required for listing objects",
                "Make sure that a valid `path` is passed for removing an object")
        }
        let input = ListObjectsV2Input(bucket: storageBehaviour.bucket,
                                       continuationToken: request.options.nextToken,
                                       delimiter: request.options.subpathStrategy.delimiter,
                                       maxKeys: Int(request.options.pageSize),
                                       prefix: path,
                                       startAfter: nil)
        do {
            let response = try await storageBehaviour.client.listObjectsV2(input: input)
            let contents: S3BucketContents = response.contents ?? []
            let items = try contents.map { s3Object in
                guard let path = s3Object.key else {
                    throw StorageError.unknown("Missing key in response")
                }
                return StorageListResult.Item(
                    path: path,
                    size: s3Object.size,
                    eTag: s3Object.eTag,
                    lastModified: s3Object.lastModified
                )
            }
            let commonPrefixes = response.commonPrefixes ?? []
            return StorageListResult(
                items: items,
                excludedSubpaths: commonPrefixes.compactMap { $0.prefix },
                nextToken: response.nextContinuationToken
            )
        } catch let error as StorageErrorConvertible {
            throw error.storageError
        } catch {
            throw StorageError.service(
                "Service error occurred.",
                "Please inspect the underlying error for more details.",
                error)
        }
    }
}
