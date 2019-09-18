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
    typealias StorageServiceDownloadEventHandler = (StorageServiceDownloadEvent) -> Void
    typealias StorageServiceDownloadEvent =
        StorageEvent<StorageOperationReference, Progress, Data?, StorageServiceError>

    typealias StorageServiceGetPreSignedURLEventHandler = (StorageServiceGetPreSignedURLEvent) -> Void
    typealias StorageServiceGetPreSignedURLEvent = StorageEvent<Void, Void, URL, StorageServiceError>

    typealias StorageServiceDeleteEventHandler = (StorageServiceDeleteEvent) -> Void
    typealias StorageServiceDeleteEvent = StorageEvent<Void, Void, Void, StorageServiceError>

    typealias StorageServiceListEventHandler = (StorageServiceListEvent) -> Void
    typealias StorageServiceListEvent = StorageEvent<Void, Void, StorageListResult, StorageServiceError>

    typealias StorageServiceUploadEventHandler = (StorageServiceUploadEvent) -> Void
    typealias StorageServiceUploadEvent =
        StorageEvent<StorageOperationReference, Progress, Void, StorageServiceError>

    typealias StorageServiceMultiPartUploadEventHandler = (StorageServiceMultiPartUploadEvent) -> Void
    typealias StorageServiceMultiPartUploadEvent =
        StorageEvent<StorageOperationReference, Progress, Void, StorageServiceError>

    func reset()

    func getEscapeHatch() -> AWSS3

    func download(serviceKey: String,
                  fileURL: URL?,
                  onEvent: @escaping StorageServiceDownloadEventHandler)

    func getPreSignedURL(serviceKey: String,
                         expires: Int,
                         onEvent: @escaping StorageServiceGetPreSignedURLEventHandler)

    func upload(serviceKey: String,
                uploadSource: UploadSource,
                contentType: String?,
                metadata: [String: String]?,
                onEvent: @escaping StorageServiceUploadEventHandler)

    func multiPartUpload(serviceKey: String,
                         uploadSource: UploadSource,
                         contentType: String?,
                         metadata: [String: String]?,
                         onEvent: @escaping StorageServiceMultiPartUploadEventHandler)

    func list(prefix: String,
              path: String?,
              onEvent: @escaping StorageServiceListEventHandler)

    func delete(serviceKey: String,
                onEvent: @escaping StorageServiceDeleteEventHandler)
}
