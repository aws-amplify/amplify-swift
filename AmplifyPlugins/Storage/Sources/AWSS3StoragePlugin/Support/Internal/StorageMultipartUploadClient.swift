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

    func cancelUploadTasks(taskIdentifiers: [TaskIdentifier], done: @escaping () -> Void)
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

class DefaultStorageMultipartUploadClient: StorageMultipartUploadClient {
    weak var serviceProxy: StorageServiceProxy?

    let fileSystem: FileSystem
    let uploadFile: UploadFile
    let bucket: String
    let key: String
    let contentType: String?
    let requestHeaders: RequestHeaders?
    weak var session: StorageMultipartUploadSession?

    init(serviceProxy: StorageServiceProxy,
         fileSystem: FileSystem = .default,
         bucket: String,
         key: String,
         uploadFile: UploadFile,
         contentType: String? = nil,
         requestHeaders: RequestHeaders? = nil) {
        self.serviceProxy = serviceProxy
        self.fileSystem = fileSystem
        self.bucket = bucket
        self.key = key
        self.uploadFile = uploadFile
        self.contentType = contentType
        self.requestHeaders = requestHeaders
    }

    func integrate(session: StorageMultipartUploadSession) {
        self.session = session
    }

    // https://docs.aws.amazon.com/AmazonS3/latest/API/API_CreateMultipartUpload.html
    func createMultipartUpload() throws {
        guard let serviceProxy = serviceProxy,
            let session = session else { fatalError() }

        // The AWS S3 SDK handles the request so there will be not taskIdentifier
        session.handle(multipartUploadEvent: .creating)

        let request = CreateMultipartUploadRequest(bucket: bucket, key: key)
        serviceProxy.awsS3.createMultipartUpload(request) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                serviceProxy.register(multipartUploadSession: session)
                session.handle(multipartUploadEvent: .created(uploadFile: self.uploadFile, uploadId: response.uploadId))
            case .failure(let error):
                session.fail(error: error)
            }
        }
    }

    // https://docs.aws.amazon.com/AmazonS3/latest/API/API_UploadPart.html
    func uploadPart(partNumber: PartNumber, multipartUpload: StorageMultipartUpload, subTask: StorageTransferTask) throws {
        guard let serviceProxy = serviceProxy else { fatalError("Service Proxy is required") }

        guard let uploadId = multipartUpload.uploadId,
              let uploadFile = multipartUpload.uploadFile,
              let partSize = multipartUpload.partSize,
              let part = multipartUpload.part(for: partNumber) else {
                  fatalError("Part number is required")
              }

        let startUploadPart: (URL, URL) -> Void = { [weak self] partialFileURL, preSignedURL in
            guard let self = self else { return }
            var request = URLRequest(url: preSignedURL)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.httpMethod = "PUT"
            request.networkServiceType = .responsiveData

            /*
            let userAgent = AWSServiceConfiguration.baseUserAgent().appending(" MultiPart")
            request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
             */

            let uploadTask = serviceProxy.urlSession.uploadTask(with: request, fromFile: partialFileURL)
            subTask.sessionTask = uploadTask
            subTask.uploadPart = multipartUpload.part(for: partNumber)

            // register task so it can be found in delegate methods
            self.serviceProxy?.register(task: subTask)

            // tell the session the upload part has started
            self.session?.handle(uploadPartEvent: .started(partNumber: partNumber, taskIdentifier: uploadTask.taskIdentifier))

            uploadTask.resume()
        }

        let partialFileResultHandler: (Result<URL, Error>) -> Void = { [weak self] result in
            guard let self = self else { return }
            Task {
                do {
                    let partialFileURL = try result.get()

                    let operation = AWSS3SigningOperation.uploadPart(partNumber: partNumber, uploadId: uploadId)
                    let preSignedURL = try await serviceProxy.preSignedURLBuilder.getPreSignedURL(
                        key: self.key,
                        signingOperation: operation,
                        expires: nil
                    )
                    startUploadPart(partialFileURL, preSignedURL)
                } catch {
                    self.session?.fail(error: error)
                }
            }
        }

        let offset = partSize.offset(for: partNumber)
        fileSystem.createPartialFile(fileURL: uploadFile.fileURL, offset: offset, length: part.bytes, completionHandler: partialFileResultHandler)
    }

    // https://docs.aws.amazon.com/AmazonS3/latest/API/API_CompleteMultipartUpload.html
    func completeMultipartUpload(uploadId: UploadID) {
        guard let serviceProxy = serviceProxy,
            let session = session else { fatalError() }

        let completedParts = session.completedParts ?? []
        let parts = AWSS3MultipartUploadRequestCompletedParts(completedParts: completedParts)
        let request = AWSS3CompleteMultipartUploadRequest(bucket: bucket, key: key, uploadId: uploadId, parts: parts)

        serviceProxy.awsS3.completeMultipartUpload(request) { result in
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
    func abortMultipartUpload(uploadId: UploadID, error: Error? = nil) {
        guard let serviceProxy = serviceProxy,
            let session = session else { fatalError() }

        serviceProxy.awsS3.abortMultipartUpload(.init(bucket: bucket, key: key, uploadId: uploadId)) { result in
            switch result {
            case .success:
                session.handle(multipartUploadEvent: .aborted(uploadId: uploadId, error: error))
            case .failure(let error):
                session.fail(error: error)
            }
            serviceProxy.unregister(multipartUploadSession: session)
        }
    }

    func cancelUploadTasks(taskIdentifiers: [TaskIdentifier], done: @escaping () -> Void) {
        guard let service = serviceProxy else { return }
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

    // Note: the headers were previously filtered in the SDK
    func filter(requestHeaders: RequestHeaders) -> RequestHeaders {
        let disallowedHeaders: Set<String> = ["x-amz-acl", "x-amz-tagging", "x-amz-storage-class", "x-amz-server-side-encryption"]
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
