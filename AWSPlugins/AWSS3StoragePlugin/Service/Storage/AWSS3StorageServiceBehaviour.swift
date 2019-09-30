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
    typealias StorageServiceDownloadEventListener = (StorageServiceDownloadEvent) -> Void
    typealias StorageServiceDownloadEvent =
        StorageEvent<StorageTaskReference, Progress, Data?, StorageError>

    typealias StorageServiceGetPreSignedURLEventListener = (StorageServiceGetPreSignedURLEvent) -> Void
    typealias StorageServiceGetPreSignedURLEvent = StorageEvent<Void, Void, URL, StorageError>

    typealias StorageServiceDeleteEventListener = (StorageServiceDeleteEvent) -> Void
    typealias StorageServiceDeleteEvent = StorageEvent<Void, Void, Void, StorageError>

    typealias StorageServiceListEventListener = (StorageServiceListEvent) -> Void
    typealias StorageServiceListEvent = StorageEvent<Void, Void, StorageListResult, StorageError>

    typealias StorageServiceUploadEventListener = (StorageServiceUploadEvent) -> Void
    typealias StorageServiceUploadEvent =
        StorageEvent<StorageTaskReference, Progress, Void, StorageError>

    typealias StorageServiceMultiPartUploadEventListener = (StorageServiceMultiPartUploadEvent) -> Void
    typealias StorageServiceMultiPartUploadEvent =
        StorageEvent<StorageTaskReference, Progress, Void, StorageError>

    func reset()

    func getEscapeHatch() -> AWSS3

    func download(serviceKey: String,
                  fileURL: URL?,
                  onEvent: @escaping StorageServiceDownloadEventListener)

    func getPreSignedURL(serviceKey: String,
                         expires: Int,
                         onEvent: @escaping StorageServiceGetPreSignedURLEventListener)

    func upload(serviceKey: String,
                uploadSource: StoragePutRequest.Source,
                contentType: String?,
                metadata: [String: String]?,
                onEvent: @escaping StorageServiceUploadEventListener)

    func multiPartUpload(serviceKey: String,
                         uploadSource: StoragePutRequest.Source,
                         contentType: String?,
                         metadata: [String: String]?,
                         onEvent: @escaping StorageServiceMultiPartUploadEventListener)

    func list(prefix: String,
              path: String?,
              onEvent: @escaping StorageServiceListEventListener)

    func delete(serviceKey: String,
                onEvent: @escaping StorageServiceDeleteEventListener)
}
