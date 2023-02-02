//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

extension AWSS3StorageService {

    func download(serviceKey: String,
                  fileURL: URL?,
                  onEvent: @escaping StorageServiceDownloadEventHandler) {
        let fail: (Error) -> Void = { error in
            let storageError = StorageError(error: error)
            onEvent(.failed(storageError))
        }

        guard attempt(try validateParameters(bucket: bucket, key: serviceKey, accelerationModeEnabled: false), fail: fail) else { return }

        let transferTask = createTransferTask(transferType: .download(onEvent: onEvent),
                                              bucket: bucket,
                                              key: serviceKey,
                                              location: fileURL)

        Task {
            do {
                let preSignedURL = try await preSignedURLBuilder.getPreSignedURL(key: serviceKey, signingOperation: .getObject, expires: nil)
                startDownload(preSignedURL: preSignedURL, transferTask: transferTask)
            } catch {
                onEvent(.failed(StorageError.unknown("Failed to get pre-signed URL", nil)))
            }
        }
    }

    private func startDownload(preSignedURL: URL,
                               transferTask: StorageTransferTask,
                               startTransfer: Bool = true) {
        guard case .download = transferTask.transferType else {
            fatalError("Transfer type must be download")
        }
        var request = URLRequest(url: preSignedURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.httpMethod = "GET"

        /*
         let userAgent = AWSServiceConfiguration.baseUserAgent()
         request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
         */

        request.setHTTPRequestHeaders(transferTask: transferTask)

        let downloadTask = urlSession.downloadTask(with: request)
        transferTask.sessionTask = downloadTask

        // log task identifier?
        logger.debug("Started download [\(downloadTask.taskIdentifier)]")

        // register task so it can be accessed in URLSession delegate functions
        register(task: transferTask)

        if startTransfer {
            transferTask.resume()
        }
    }
}
