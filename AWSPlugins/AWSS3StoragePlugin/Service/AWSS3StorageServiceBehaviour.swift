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
                   cognitoCredentialsProvider: AWSCognitoCredentialsProvider,
                   identifier: String) throws

    func reset()

    func getEscapeHatch() -> AWSS3

    func download(bucket: String,
                  serviceKey: String,
                  fileURL: URL?,
                  onEvent: @escaping StorageDownloadOnEventHandler)

    func getPreSignedURL(bucket: String,
                         serviceKey: String,
                         expires: Int?,
                         onEvent: @escaping StorageGetPreSignedUrlOnEventHandler)

    func upload(bucket: String,
                serviceKey: String,
                key: String,
                fileURL: URL?,
                data: Data?,
                contentType: String?,
                onEvent: @escaping StorageUploadOnEventHandler)

    func multiPartUpload(bucket: String,
                         serviceKey: String,
                         key: String,
                         fileURL: URL?,
                         data: Data?,
                         contentType: String?,
                         onEvent: @escaping StorageMultiPartUploadOnEventHandler)

    func list(bucket: String,
                     prefix: String,
                     onEvent: @escaping StorageListOnEventHandler)

    func delete(bucket: String,
                      serviceKey: String,
                      onEvent: @escaping StorageDeleteOnEventHandler)
}
