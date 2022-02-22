//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import AWSS3
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
    func reportSessionActivity(_ message: String) {
        logger.info(message)
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

// MARK:  - URLSessionDelegate -

extension StorageServiceSessionDelegate: URLSessionDelegate {

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        reportSessionActivity("[URLSession] session did finish background events")

        if let identifier = storageService?.identifier,
           let handler = StorageBackgroundEventsRegistry.findCompletionHandler(for: identifier) {
            // Must be run on main thread as covered by Apple Developer docs.
            DispatchQueue.main.async(execute: handler)
            StorageBackgroundEventsRegistry.removeCompletionHandler(for: identifier)
        }
    }

    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        reportSessionActivity("[URLSession] session did become invalid: \(identifier)")

        if let error = error {
            logger.error(error: error)
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
            reportSessionActivity("[URLSession] session task did complete with error: \(task.taskIdentifier) [\(error)]")
        } else {
            reportSessionActivity("[URLSession] session task did complete: \(task.taskIdentifier)")
        }

        guard let storageService = storageService,
              let transferTask = findTransferTask(for: task.taskIdentifier) else { return }

        if let error = error {
            transferTask.fail(error: error)
            storageService.unregister(task: transferTask)
            return
        }

        switch transferTask.transferType {
        case .multiPartUploadPart(let uploadId, let partNumber):
            guard let eTag = task.eTag else {
                logger.error("[URLSession] Completed upload part does not include header value for ETAG: [\(partNumber), \(uploadId)]")
                return
            }

            guard let multipartUploadSession = storageService.findMultipartUploadSession(uploadId: uploadId) else {
                logger.info("[URLSession] MultipartUpload not found for uploadId: \(uploadId)")
                return
            }

            multipartUploadSession.handle(uploadPartEvent: .completed(partNumber: partNumber, eTag: eTag, taskIdentifier: task.taskIdentifier))
            transferTask.complete()
            storageService.unregister(task: transferTask)
        case .upload(let onEvent):
            onEvent(.completed(()))
            transferTask.complete()
            storageService.unregister(task: transferTask)
        default:
            logger.debug("[URLSession] Transfer Type not supported by \(#function): [\(transferTask.transferType.name)]")
        }

    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        reportSessionActivity("[URLSession] session task update: [bytesSent: \(bytesSent)], [totalBytesSent: \(totalBytesSent)], [totalBytesExpectedToSend: \(totalBytesExpectedToSend)]")

        guard let storageService = storageService,
              let transferTask = findTransferTask(for: task.taskIdentifier) else { return }

        switch transferTask.transferType {
        case .multiPartUploadPart(let uploadId, let partNumber):
            guard let multipartUploadSession = storageService.findMultipartUploadSession(uploadId: uploadId) else {
                logger.info("[URLSession] MultipartUpload not found for uploadId: \(uploadId)")
                return
            }

            multipartUploadSession.handle(uploadPartEvent: .progressUpdated(partNumber: partNumber, bytesTransferred: Int(bytesSent), taskIdentifier: task.taskIdentifier))
        case .upload(let onEvent):
            let progress = Progress(totalUnitCount: totalBytesExpectedToSend)
            progress.completedUnitCount = totalBytesSent
            onEvent(.inProcess(progress))
        default:
            logger.debug("[URLSession] Transfer Type not supported by \(#function): [\(transferTask.transferType.name)]")
        }

    }

}

// MARK: - URLSessionDownloadDelegate -

extension StorageServiceSessionDelegate: URLSessionDownloadDelegate {

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        reportSessionActivity("[URLSession] session download task [\(downloadTask.taskIdentifier)] did write [\(bytesWritten)], [totalBytesWritten \(totalBytesWritten)], [totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)]")

        guard let transferTask = findTransferTask(for: downloadTask.taskIdentifier) else { return }

        let progress = Progress(totalUnitCount: totalBytesExpectedToWrite)
        progress.completedUnitCount = totalBytesWritten
        transferTask.transferType.notify(progress: progress)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        reportSessionActivity("[URLSession] session download task  [\(downloadTask.taskIdentifier)] did finish downloading to \(location.path)")

        guard let storageService = storageService,
              let transferTask = findTransferTask(for: downloadTask.taskIdentifier) else { return }

        storageService.completeDownload(taskIdentifier: downloadTask.taskIdentifier, sourceURL: location)
        storageService.unregister(task: transferTask)
    }

}
