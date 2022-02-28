//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSS3

protocol AWSS3StorageServiceBehaviour {
    typealias StorageServiceDownloadEventHandler = (StorageServiceDownloadEvent) -> Void
    typealias StorageServiceDownloadEvent =
        StorageEvent<StorageTaskReference, Progress, Data?, StorageError>

    // swiftlint:disable:next type_name
    typealias StorageServiceGetPreSignedURLEventHandler = (StorageServiceGetPreSignedURLEvent) -> Void
    typealias StorageServiceGetPreSignedURLEvent = StorageEvent<Void, Void, URL, StorageError>

    typealias StorageServiceDeleteEventHandler = (StorageServiceDeleteEvent) -> Void
    typealias StorageServiceDeleteEvent = StorageEvent<Void, Void, Void, StorageError>

    typealias StorageServiceListEventHandler = (StorageServiceListEvent) -> Void
    typealias StorageServiceListEvent = StorageEvent<Void, Void, StorageListResult, StorageError>

    typealias StorageServiceUploadEventHandler = (StorageServiceUploadEvent) -> Void
    typealias StorageServiceUploadEvent =
        StorageEvent<StorageTaskReference, Progress, Void, StorageError>

    // swiftlint:disable:next type_name
    typealias StorageServiceMultiPartUploadEventHandler = (StorageServiceMultiPartUploadEvent) -> Void
    typealias StorageServiceMultiPartUploadEvent =
        StorageEvent<StorageTaskReference, Progress, Void, StorageError>

    func reset()

    func getEscapeHatch() -> S3Client

    func download(serviceKey: String,
                  fileURL: URL?,
                  onEvent: @escaping StorageServiceDownloadEventHandler)

    func getPreSignedURL(serviceKey: String,
                         method: AWSS3HttpMethod,
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

extension AWSS3StorageServiceBehaviour {
    func getPreSignedURL(serviceKey: String,
                         expires: Int,
                         onEvent: @escaping StorageServiceGetPreSignedURLEventHandler) {
        getPreSignedURL(serviceKey: serviceKey, method: .get, expires: expires, onEvent: onEvent)
    }
}
