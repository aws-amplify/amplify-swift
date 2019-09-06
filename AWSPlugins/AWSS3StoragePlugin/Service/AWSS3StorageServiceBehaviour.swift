//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSS3

public typealias StorageDownloadOnEventHandler =
    (StorageEvent<StorageOperationReference, Progress, StorageGetResult, StorageGetError>) -> Void

public typealias StorageGetPreSignedUrlOnEventHandler =
    (StorageEvent<StorageOperationReference, Progress, StorageGetResult, StorageGetError>) -> Void

public typealias StorageDeleteOnEventHandler =
    (StorageEvent<Void, Void, StorageRemoveResult, StorageRemoveError>) -> Void

public typealias StorageListOnEventHandler =
    (StorageEvent<Void, Void, StorageListResult, StorageListError>) -> Void

public typealias StorageUploadOnEventHandler =
    (StorageEvent<StorageOperationReference, Progress, StoragePutResult, StoragePutError>) -> Void

public typealias StorageMultiPartUploadOnEventHandler =
    (StorageEvent<StorageOperationReference, Progress, StoragePutResult, StoragePutError>) -> Void

protocol AWSS3StorageServiceBehaviour {
    func configure(region: AWSRegionType,
                   bucket: String,
                   cognitoCredentialsProvider: AWSCognitoCredentialsProvider,
                   identifier: String) throws

    func reset()

    func getEscapeHatch() -> AWSS3

    func download(serviceKey: String,
                  fileURL: URL?,
                  onEvent: @escaping StorageDownloadOnEventHandler)

    func getPreSignedURL(serviceKey: String,
                         expires: Int?,
                         onEvent: @escaping StorageGetPreSignedUrlOnEventHandler)

    func upload(serviceKey: String,
                key: String,
                uploadSource: UploadSource,
                contentType: String?,
                onEvent: @escaping StorageUploadOnEventHandler)

    func multiPartUpload(serviceKey: String,
                         key: String,
                         uploadSource: UploadSource,
                         contentType: String?,
                         onEvent: @escaping StorageMultiPartUploadOnEventHandler)

    func list(prefix: String,
              onEvent: @escaping StorageListOnEventHandler)

    func delete(serviceKey: String,
                onEvent: @escaping StorageDeleteOnEventHandler)
}
