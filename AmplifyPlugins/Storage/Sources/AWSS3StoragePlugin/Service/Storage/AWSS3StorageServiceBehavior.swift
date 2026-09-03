//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSS3
import Foundation

typealias AWSS3StorageServiceProvider = () throws -> AWSS3StorageServiceBehavior
protocol AWSS3StorageServiceBehavior {
    typealias StorageServiceDownloadEventHandler = @Sendable (StorageServiceDownloadEvent) -> Void
    typealias StorageServiceDownloadEvent =
        StorageEvent<StorageTaskReference, Progress, Data?, StorageError>

    // swiftlint:disable:next type_name
    typealias StorageServiceGetPreSignedURLEventHandler = @Sendable (StorageServiceGetPreSignedURLEvent) -> Void
    typealias StorageServiceGetPreSignedURLEvent = StorageEvent<Void, Void, URL, StorageError>

    typealias StorageServiceDeleteEventHandler = @Sendable (StorageServiceDeleteEvent) -> Void
    typealias StorageServiceDeleteEvent = StorageEvent<Void, Void, Void, StorageError>

    typealias StorageServiceListEventHandler = @Sendable (StorageServiceListEvent) -> Void
    typealias StorageServiceListEvent = StorageEvent<Void, Void, StorageListResult, StorageError>

    typealias StorageServiceUploadEventHandler = @Sendable (StorageServiceUploadEvent) -> Void
    typealias StorageServiceUploadEvent =
        StorageEvent<StorageTaskReference, Progress, Void, StorageError>

    // swiftlint:disable:next type_name
    typealias StorageServiceMultiPartUploadEventHandler = @Sendable (StorageServiceMultiPartUploadEvent) -> Void
    typealias StorageServiceMultiPartUploadEvent =
        StorageEvent<StorageTaskReference, Progress, Void, StorageError>


    /// - Tag: AWSS3StorageService.client
    var client: S3ClientProtocol { get }

    var bucket: String! { get }

    func reset()

    func getEscapeHatch() -> S3Client

    func download(
        serviceKey: String,
        fileURL: URL?,
        accelerate: Bool?,
        onEvent: @escaping StorageServiceDownloadEventHandler
    )

    func getPreSignedURL(
        serviceKey: String,
        signingOperation: AWSS3SigningOperation,
        metadata: [String: String]?,
        accelerate: Bool?,
        expires: Int
    ) async throws -> URL

    func validateObjectExistence(serviceKey: String) async throws

    func upload(
        serviceKey: String,
        uploadSource: UploadSource,
        contentType: String?,
        metadata: [String: String]?,
        accelerate: Bool?,
        progressStallTimeoutSeconds: TimeInterval,
        onEvent: @escaping StorageServiceUploadEventHandler
    )

    func multiPartUpload(
        serviceKey: String,
        uploadSource: UploadSource,
        contentType: String?,
        metadata: [String: String]?,
        accelerate: Bool?,
        progressStallTimeoutSeconds: TimeInterval,
        onEvent: @escaping StorageServiceMultiPartUploadEventHandler
    )

    @available(*, deprecated, message: "Use `AWSS3StorageListObjectsTask` instead")
    func list(
        prefix: String,
        options: StorageListRequest.Options
    ) async throws -> StorageListResult

    @available(*, deprecated, message: "Use `AWSS3StorageRemoveTask` instead")
    func delete(
        serviceKey: String,
        onEvent: @escaping StorageServiceDeleteEventHandler
    )
}
