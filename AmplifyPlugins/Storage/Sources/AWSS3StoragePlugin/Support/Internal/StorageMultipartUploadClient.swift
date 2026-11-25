//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import Amplify
import AWSPluginsCore

protocol StorageMultipartUploadClient {
    func integrate(session: StorageMultipartUploadSession)

    func createMultipartUpload() throws
    func uploadPart(partNumber: PartNumber, multipartUpload: StorageMultipartUpload, subTask: StorageTransferTask) throws
    func completeMultipartUpload(uploadId: UploadID) throws
    func abortMultipartUpload(uploadId: UploadID, error: Error?) throws

    func cancelUploadTasks(taskIdentifiers: [TaskIdentifier], done: @escaping @Sendable () -> Void)
}

extension StorageMultipartUploadClient {
    func abortMultipartUpload(uploadId: UploadID) throws {
        try abortMultipartUpload(uploadId: uploadId, error: nil)
    }
}

// Note: This may  be helpful in switching between Objective-C and Swift SDKs.
protocol StorageCreateMultipartUploadResponse {
    var uploadId: UploadID? { get }
}

/// - Note: `@unchecked Sendable`: upload part work is dispatched to tasks that reach
///   back into the client, and its state is confined to a single upload session.
class DefaultStorageMultipartUploadClient: StorageMultipartUploadClient, @unchecked Sendable {
    weak var serviceProxy: StorageServiceProxy?

    let fileSystem: FileSystem
    let uploadFile: UploadFile
    let bucket: String
    let key: String
    let contentType: String?
    let requestHeaders: RequestHeaders?
    weak var session: StorageMultipartUploadSession?
    let metadata: [String: String]?
    private let logger: Logger

    init(
        serviceProxy: StorageServiceProxy,
        fileSystem: FileSystem = .default,
        bucket: String,
        key: String,
        uploadFile: UploadFile,
        contentType: String? = nil,
        requestHeaders: RequestHeaders? = nil,
        metadata: [String: String]? = nil,
        logger: Logger = storageLogger
    ) {
        self.serviceProxy = serviceProxy
        self.fileSystem = fileSystem
        self.bucket = bucket
        self.key = key
        self.uploadFile = uploadFile
        self.contentType = contentType
        self.requestHeaders = requestHeaders
        self.metadata = metadata
        self.logger = logger
    }

    func integrate(session: StorageMultipartUploadSession) {
        self.session = session
    }

    // https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateMultipartUpload.html
    func createMultipartUpload() throws {
        guard let session else { throw Self.sessionUnavailable }
        guard let serviceProxy, let awsS3 = serviceProxy.awsS3 else { throw Self.serviceUnavailable }

        // The AWS S3 SDK handles the request so there will be not taskIdentifier
        session.handle(multipartUploadEvent: .creating)

        // User-defined metadata needs to provided
        // when initiating the MPU.
        // --
        // https://docs.aws.amazon.com/AmazonS3/latest/userguide/mpuoverview.html#mpu-process
        // > Multipart upload initiation
        // "If you want to provide any metadata describing the object
        // being uploaded, you must provide it in the request to initiate
        // multipart upload."
        let request = CreateMultipartUploadRequest(
            bucket: bucket,
            key: key,
            metadata: metadata
        )
        awsS3.createMultipartUpload(request) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let response):
                serviceProxy.register(multipartUploadSession: session)
                session.handle(multipartUploadEvent: .created(uploadFile: uploadFile, uploadId: response.uploadId))
            case .failure(let error):
                session.fail(error: error)
            }
        }
    }

    // https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html
    func uploadPart(partNumber: PartNumber, multipartUpload: StorageMultipartUpload, subTask: StorageTransferTask) throws {
        // A concurrent cancel() or failure can move the session past `.parts` before the caller takes this
        // snapshot (#4407); the new state owns the outcome, so there is no part to start.
        guard let uploadId = multipartUpload.uploadId,
              let uploadFile = multipartUpload.uploadFile,
              let partSize = multipartUpload.partSize else {
            return
        }
        guard let part = multipartUpload.part(for: partNumber) else {
            throw StorageError.unknown("Part number \(partNumber) is not in this multipart upload", nil)
        }
        guard let serviceProxy else { throw Self.serviceUnavailable }

        // `@Sendable` because the result handler below captures this and calls it from a `Task`.
        let startUploadPart: @Sendable (URL, URL) async -> Void = { [weak self] partialFileURL, preSignedURL in
            guard let self else { return }
            var request = URLRequest(url: preSignedURL)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.httpMethod = "PUT"
            request.networkServiceType = .responsiveData

            // Because this request represents an
            // [UploadPart](https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html)
            // operation, the "MultiPart/UploadPart" suffix is added to the
            // user agent.
            let userAgent = await serviceProxy.userAgent.appending(" MultiPart/UploadPart")
            request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

            self.serviceProxy?.urlRequestDelegate?.willSend(request: request)
            let uploadTask = serviceProxy.urlSession.uploadTask(with: request, fromFile: partialFileURL)
            self.serviceProxy?.urlRequestDelegate?.didSend(request: request)

            subTask.sessionTask = uploadTask
            subTask.uploadPart = multipartUpload.part(for: partNumber)

            // register task so it can be found in delegate methods
            self.serviceProxy?.register(task: subTask)

            // tell the session the upload part has started
            session?.handle(uploadPartEvent: .started(partNumber: partNumber, taskIdentifier: uploadTask.taskIdentifier))

            // A pause, cancel or failure while this part was being prepared drops `.started` (#4407): don't send it.
            // Unregister first, so the delegate doesn't report the cancellation as a part failure.
            guard case .inProgress(_, _, let taskIdentifier)? = session?.part(for: partNumber),
                  taskIdentifier == uploadTask.taskIdentifier else {
                self.serviceProxy?.unregister(task: subTask)
                uploadTask.cancel()
                return
            }
            uploadTask.resume()
        }

        let partialFileResultHandler: @Sendable (Result<URL, Error>) -> Void = { [weak self] result in
            guard let self else { return }
            Task {
                do {
                    let partialFileURL = try result.get()
                    defer {
                        // Clean up the temporary file after we're done with it
                        self.fileSystem.removeFileIfExists(fileURL: partialFileURL)
                    }

                    let operation = AWSS3SigningOperation.uploadPart(partNumber: partNumber, uploadId: uploadId)
                    guard let preSignedURLBuilder = serviceProxy.preSignedURLBuilder else { throw Self.serviceUnavailable }
                    let preSignedURL = try await preSignedURLBuilder.getPreSignedURL(
                        key: self.key,
                        signingOperation: operation,
                        // user-controlled metadata should *not* be provided
                        // with each upload part.
                        metadata: nil,
                        accelerate: nil,
                        expires: nil
                    )
                    await startUploadPart(partialFileURL, preSignedURL)
                } catch {
                    self.session?.fail(error: error)
                }
            }
        }

        let offset = partSize.offset(for: partNumber)
        fileSystem.createPartialFile(fileURL: uploadFile.fileURL, offset: offset, length: part.bytes, completionHandler: partialFileResultHandler)
    }

    // https://docs.aws.amazon.com/AmazonS3/latest/API/API_CompleteMultipartUpload.html
    func completeMultipartUpload(uploadId: UploadID) throws {
        guard let session else { throw Self.sessionUnavailable }
        guard let serviceProxy, let awsS3 = serviceProxy.awsS3 else { throw Self.serviceUnavailable }

        let completedParts = session.completedParts ?? []
        let parts = AWSS3MultipartUploadRequestCompletedParts(completedParts: completedParts)
        let request = AWSS3CompleteMultipartUploadRequest(bucket: bucket, key: key, uploadId: uploadId, parts: parts)

        awsS3.completeMultipartUpload(request) { result in
            switch result {
            case .success:
                session.handle(multipartUploadEvent: .completed(uploadId: uploadId))
            case .failure(let error):
                session.fail(error: error)
            }
            serviceProxy.unregister(multipartUploadSession: session)
        }
    }

    // https://docs.aws.amazon.com/AmazonS3/latest/API/API_AbortMultipartUpload.html
    func abortMultipartUpload(uploadId: UploadID, error: Error? = nil) throws {
        guard let session else { throw Self.sessionUnavailable }
        guard let serviceProxy, let awsS3 = serviceProxy.awsS3 else {
            // Nothing can send the abort (#4426), so end the session as S3's response would, on another queue.
            logger.warn("AbortMultipartUpload not sent, the storage service is no longer available: \(uploadId)")
            DispatchQueue.global().async {
                session.handle(multipartUploadEvent: .aborted(uploadId: uploadId, error: error ?? Self.serviceUnavailable))
            }
            return
        }

        awsS3.abortMultipartUpload(.init(bucket: bucket, key: key, uploadId: uploadId)) { result in
            switch result {
            case .success:
                session.handle(multipartUploadEvent: .aborted(uploadId: uploadId, error: error))
            case .failure(let error):
                session.fail(error: error)
            }
            serviceProxy.unregister(multipartUploadSession: session)
        }
    }

    func cancelUploadTasks(taskIdentifiers: [TaskIdentifier], done: @escaping @Sendable () -> Void) {
        // pause() waits for `done`.
        guard let service = serviceProxy else {
            done()
            return
        }
        service.unregister(taskIdentifiers: taskIdentifiers)
        service.urlSession.getActiveTasks { tasks in
            for task in tasks {
                if taskIdentifiers.contains(task.taskIdentifier) {
                    task.cancel()
                }
            }
            done()
        }
    }

    // MARK: - Private -

    // `serviceProxy` is weak: a plugin reset, or a storage service replaced mid-upload, releases or resets it (#4426).
    private static var serviceUnavailable: StorageError {
        .unknown("The storage service that started this multipart upload is no longer available", nil)
    }

    private static var sessionUnavailable: StorageError {
        .unknown("The multipart upload session is no longer available", nil)
    }

    // Note: the headers were previously filtered in the SDK
    func filter(requestHeaders: RequestHeaders) -> RequestHeaders {
        let disallowedHeaders: Set = ["x-amz-acl", "x-amz-tagging", "x-amz-storage-class", "x-amz-server-side-encryption"]
        let shouldExcludeKey: (String) -> Bool = {
            $0.hasPrefix("x-amz-meta") ||
            $0.hasPrefix("x-amz-grant") ||
                disallowedHeaders.contains($0)
        }
        let result = requestHeaders.filter { key, _ in
            !shouldExcludeKey(key)
        }
        return result
    }

}
