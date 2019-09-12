//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSS3

protocol AWSS3StorageServiceBehaviour {
    typealias StorageDownloadOnEventHandler = (StorageDownloadOnEvent) -> Void
    typealias StorageDownloadOnEvent =
        StorageEvent<StorageOperationReference, Progress, StorageGetResult, StorageGetError>

    typealias StorageGetPreSignedURLOnEventHandler = (StorageGetPreSignedURLOnEvent) -> Void
    typealias StorageGetPreSignedURLOnEvent =
        StorageEvent<StorageOperationReference, Progress, StorageGetResult, StorageGetError>

    typealias StorageDeleteOnEventHandler = (StorageDeleteOnEvent) -> Void
    typealias StorageDeleteOnEvent = StorageEvent<Void, Void, StorageRemoveResult, StorageRemoveError>

    typealias StorageListOnEventHandler = (StorageListOnEvent) -> Void
    typealias StorageListOnEvent = StorageEvent<Void, Void, StorageListResult, StorageListError>

    typealias StorageUploadOnEventHandler = (StorageUploadOnEvent) -> Void
    typealias StorageUploadOnEvent =
        StorageEvent<StorageOperationReference, Progress, StoragePutResult, StoragePutError>

    typealias StorageMultiPartUploadOnEventHandler = (StorageMultiPartUploadOnEvent) -> Void
    typealias StorageMultiPartUploadOnEvent =
        StorageEvent<StorageOperationReference, Progress, StoragePutResult, StoragePutError>

    func configure(region: AWSRegionType,
                   bucket: String,
                   cognitoCredentialsProvider: AWSCognitoCredentialsProvider,
                   identifier: String) throws

    func reset()

    func getEscapeHatch() -> AWSS3?

    func download(serviceKey: String,
                  fileURL: URL?,
                  onEvent: @escaping StorageDownloadOnEventHandler)

    func getPreSignedURL(serviceKey: String,
                         expires: Int?,
                         onEvent: @escaping StorageGetPreSignedURLOnEventHandler)

    func upload(serviceKey: String,
                key: String,
                uploadSource: UploadSource,
                contentType: String?,
                metadata: [String: String]?,
                onEvent: @escaping StorageUploadOnEventHandler)

    func multiPartUpload(serviceKey: String,
                         key: String,
                         uploadSource: UploadSource,
                         contentType: String?,
                         metadata: [String: String]?,
                         onEvent: @escaping StorageMultiPartUploadOnEventHandler)

    func list(prefix: String,
              path: String?,
              onEvent: @escaping StorageListOnEventHandler)

    func delete(serviceKey: String,
                onEvent: @escaping StorageDeleteOnEventHandler)
}
