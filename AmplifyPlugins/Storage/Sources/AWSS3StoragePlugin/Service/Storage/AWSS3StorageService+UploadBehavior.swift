//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension AWSS3StorageService {

    func upload(serviceKey: String,
                uploadSource: UploadSource,
                contentType: String?,
                metadata: [String: String]?,
                accelerate: Bool?,
                onEvent: @escaping StorageServiceUploadEventHandler) {
        let fail: (Error) -> Void = { error in
            let storageError = StorageError(error: error)
            onEvent(.failed(storageError))
        }

        guard attempt(try validateParameters(bucket: bucket, key: serviceKey, accelerationModeEnabled: false), fail: fail) else { return }

        Task {
            let transferTask = createTransferTask(transferType: .upload(onEvent: onEvent),
                                                  bucket: bucket,
                                                  key: serviceKey)
            let uploadFileURL: URL
            guard let uploadFile = attempt(try uploadSource.getFile(), fail: fail) else { return }
            uploadFileURL = uploadFile.fileURL

            let contentType = contentType ?? "application/octet-stream"

            do {
                let preSignedURL = try await preSignedURLBuilder.getPreSignedURL(key: serviceKey,
                                                                                 signingOperation: .putObject,
                                                                                 accelerate: accelerate,
                                                                                 expires: nil)
                startUpload(preSignedURL: preSignedURL,
                            fileURL: uploadFileURL,
                            contentType: contentType,
                            transferTask: transferTask)
            } catch {
                onEvent(.failed(StorageError.unknown("Failed to get pre-signed URL", nil)))
            }
        }
    }

    func startUpload(preSignedURL: URL,
                     fileURL: URL,
                     contentType: String,
                     transferTask: StorageTransferTask,
                     startTransfer: Bool = true) {
        guard case .upload = transferTask.transferType else {
            fatalError("Transfer type must be upload")
        }
        var request = URLRequest(url: preSignedURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.httpMethod = "PUT"
        request.networkServiceType = .responsiveData

        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        request.setHTTPRequestHeaders(transferTask: transferTask)

        urlRequestDelegate?.willSend(request: request)
        let uploadTask = urlSession.uploadTask(with: request, fromFile: fileURL)
        urlRequestDelegate?.didSend(request: request)
        transferTask.sessionTask = uploadTask

        // log task identifier?
        logger.debug("Started upload [\(uploadTask.taskIdentifier)]")

        // register task so it can be accessed in URLSession delegate functions
        register(task: transferTask)

        if startTransfer {
            transferTask.resume()
        }
    }
}
