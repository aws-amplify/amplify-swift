//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import Amplify
import AWSPluginsCore

// MARK: - StorageServiceSessionDelegate -

class StorageServiceSessionDelegate: NSObject {
    let identifier: String
    let logger: Logger
    weak var storageService: AWSS3StorageService?

    init(identifier: String, logger: Logger = storageLogger) {
        self.identifier = identifier
        self.logger = logger
    }

    // Set a Symbolic Breakpoint in Xcode to monitor these messages
    func logURLSessionActivity(_ message: String, warning: Bool = false) {
        if warning {
            logger.warn("[URLSession] \(message)")
        } else {
            logger.info("[URLSession] \(message)")
        }
    }

    private func findTransferTask(for taskIdentifier: TaskIdentifier) -> StorageTransferTask? {
        guard let storageService = storageService,
              let transferTask = storageService.findTask(taskIdentifier: taskIdentifier) else {
                  logger.debug("Did not find transfer task: \(taskIdentifier)")
                  return nil
              }
        return transferTask
    }
}

public extension Notification.Name {
    static let StorageURLSessionDidBecomeInvalidNotification = Notification.Name("URLSessionDidBecomeInvalidNotification")
    static let reachabilityChanged = Notification.Name("reachabilityChanged")
}

// MARK: - URLSessionDelegate -

extension StorageServiceSessionDelegate: URLSessionDelegate {

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        logURLSessionActivity("Session did finish background events")

        if let identifier = storageService?.identifier,
           let continuation = StorageBackgroundEventsRegistry.getContinuation(for: identifier) {
            // Must be run on main thread as covered by Apple Developer docs.
            Task { @MainActor in
                continuation.resume(returning: true)
            }
            StorageBackgroundEventsRegistry.removeContinuation(for: identifier)
        }
    }

    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        if let error = error {
            logURLSessionActivity("Session did become invalid: \(identifier) [\(error)]", warning: true)
        } else {
            logURLSessionActivity("Session did become invalid: \(identifier)")
        }

        // The Storage plugin must be reset and configured again when the session becomes invalid.
        NotificationCenter.default.post(name: Notification.Name.StorageURLSessionDidBecomeInvalidNotification, object: session)

        // Reset URLSession since the current one has become invalid.
        storageService?.resetURLSession()
    }
}

// MARK: - URLSessionTaskDelegate -

extension StorageServiceSessionDelegate: URLSessionTaskDelegate {

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled {
                logURLSessionActivity("Session task cancelled: \(task.taskIdentifier)")
                return
            }
            logURLSessionActivity("Session task did complete with error: \(task.taskIdentifier) [\(error)]", warning: true)
        } else {
            logURLSessionActivity("Session task did complete: \(task.taskIdentifier)")
        }

        guard let storageService = storageService,
              let transferTask = findTransferTask(for: task.taskIdentifier) else {
                  logURLSessionActivity("Session task not handled: \(task.taskIdentifier)")
                  return
              }

        let response = StorageTransferResponse(task: task, error: error, transferTask: transferTask)
        if let responseError = response.responseError {
            transferTask.fail(error: responseError)
            storageService.unregister(task: transferTask)
            logURLSessionActivity("Failed with error: \(responseError)", warning: true)
            if response.isErrorRetriable {
                logURLSessionActivity("Task can be retried.")
            }
            return
        }

        switch transferTask.transferType {
        case .multiPartUploadPart(let uploadId, let partNumber):
            guard let multipartUploadSession = storageService.findMultipartUploadSession(uploadId: uploadId) else {
                logURLSessionActivity("MultipartUpload not found for uploadId: \(uploadId)")
                return
            }

            guard let eTag = task.eTag else {
                let message = "Completed upload part does not include header value for ETAG: [\(partNumber), \(uploadId)]"
                logURLSessionActivity(message, warning: true)
                multipartUploadSession.handle(uploadPartEvent: .failed(partNumber: partNumber, error: StorageError.unknown("Upload for part number does not include value for eTag", nil)))
                return
            }

            multipartUploadSession.handle(uploadPartEvent: .completed(partNumber: partNumber, eTag: eTag, taskIdentifier: task.taskIdentifier))
            transferTask.complete()
            storageService.unregister(task: transferTask)
        case .upload(let onEvent):
            onEvent(.completed(()))
            transferTask.complete()
            storageService.unregister(task: transferTask)
        case .download:
            storageService.unregister(task: transferTask)
        default:
            logger.debug("Transfer Type not supported by \(#function): [\(transferTask.transferType.name)]")
        }

    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        logURLSessionActivity("Session task update: [bytesSent: \(bytesSent)], [totalBytesSent: \(totalBytesSent)], [totalBytesExpectedToSend: \(totalBytesExpectedToSend)]")

        guard let storageService = storageService,
              let transferTask = findTransferTask(for: task.taskIdentifier) else { return }

        switch transferTask.transferType {
        case .multiPartUploadPart(let uploadId, let partNumber):
            guard let multipartUploadSession = storageService.findMultipartUploadSession(uploadId: uploadId) else {
                logURLSessionActivity("MultipartUpload not found for uploadId: \(uploadId)")
                return
            }

            multipartUploadSession.handle(uploadPartEvent: .progressUpdated(partNumber: partNumber, bytesTransferred: Int(bytesSent), taskIdentifier: task.taskIdentifier))
        case .upload(let onEvent):
            let progress = Progress(totalUnitCount: totalBytesExpectedToSend)
            progress.completedUnitCount = totalBytesSent
            onEvent(.inProcess(progress))
        default:
            logger.debug("Transfer Type not supported by \(#function): [\(transferTask.transferType.name)]")
        }

    }

}

// MARK: - URLSessionDownloadDelegate -

extension StorageServiceSessionDelegate: URLSessionDownloadDelegate {

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        logURLSessionActivity("Session download task [\(downloadTask.taskIdentifier)] did write [\(bytesWritten)], [totalBytesWritten \(totalBytesWritten)], [totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)]")

        guard let transferTask = findTransferTask(for: downloadTask.taskIdentifier) else { return }

        let progress = Progress(totalUnitCount: totalBytesExpectedToWrite)
        progress.completedUnitCount = totalBytesWritten
        transferTask.transferType.notify(progress: progress)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        logURLSessionActivity("Session download task [\(downloadTask.taskIdentifier)] did finish downloading to \(location.path)")

        guard let storageService = storageService,
              let transferTask = findTransferTask(for: downloadTask.taskIdentifier) else { return }

        let response = StorageTransferResponse(task: downloadTask, error: nil, transferTask: transferTask)

        if let responseError = response.responseError {
            logURLSessionActivity("Response Error: \(responseError)")
            if let contents = try? String(contentsOf: location) {
                logURLSessionActivity("Contents:\n\(contents)")
            }
        } else {
            storageService.completeDownload(taskIdentifier: downloadTask.taskIdentifier, sourceURL: location)
        }
    }

}
