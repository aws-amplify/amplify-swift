//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

class StorageTransferTask {
    let transferID: String
    let transferType: StorageTransferType
    let bucket: String
    let key: String

    let storageTransferDatabase: StorageTransferDatabase
    let logger: Logger

    internal var sessionTask: StorageSessionTask? {
        didSet {
            if sessionTask?.state == .suspended {
                status = .paused
            }
        }
    }
    internal private(set) var status: StorageTransferStatus = .unknown
    internal var location: URL?
    internal var error: Error?

    // support for multipart uploads
    internal var uploadId: UploadID?
    internal var multipartUpload: StorageMultipartUpload? {
        didSet {
            if let multipartUpload = multipartUpload {
                if multipartUpload.inProgress {
                    status = .inProgress
                } else if multipartUpload.isPaused {
                    status = .paused
                } else if multipartUpload.isCompleted {
                    status = .completed
                } else if multipartUpload.isAborted {
                    status = .completed
                } else if multipartUpload.isFailed {
                    status = .error
                }
            }
        }
    }
    internal var uploadPart: StorageUploadPart?

    // proxy for StorageMultipartUploadSession
    internal var proxyStorageTask: StorageTask?

    internal var partNumber: PartNumber? {
        switch transferType {
        case .multiPartUploadPart(_, let partNumber):
            return partNumber
        default:
            return nil
        }
    }

    internal private(set) var contentType: String?
    internal private(set) var requestHeaders: [String: String]?

    internal private(set) var file: String?
    internal private(set) var retryCount: Int = 0
    internal private(set) var retryLimit: Int = 3

    internal var responseData: Data?
    internal var responseText: String? {
        guard let data = responseData, data.count < 5_120,
            let text = String(bytes: data, encoding: .utf8) else {
            return nil
        }
        return text
    }

    init(transferID: String = UUID().uuidString,
         transferType: StorageTransferType,
         bucket: String,
         key: String,
         location: URL? = nil,
         contentType: String? = nil,
         requestHeaders: [String: String]? = nil,
         storageTransferDatabase: StorageTransferDatabase = .default,
         logger: Logger = storageLogger) {
        self.transferID = transferID
        self.transferType = transferType
        self.bucket = bucket
        self.key = key
        self.location = location
        self.contentType = contentType
        self.requestHeaders = requestHeaders
        self.storageTransferDatabase = storageTransferDatabase
        self.logger = logger

        storageTransferDatabase.insertTransferRequest(task: self)
    }

    init(persistableTransferTask: StoragePersistableTransferTask,
         transferType: StorageTransferType,
         sessionTask: StorageSessionTask? = nil,
         storageTransferDatabase: StorageTransferDatabase = .default,
         logger: Logger = storageLogger) {

        // swiftlint:disable line_length
        guard let rawValue = StorageTransferType.RawValues(rawValue: persistableTransferTask.transferTypeRawValue) else {
            fatalError("rawValue is required")
        }
        // swiftlint:enable line_length

        self.transferID = persistableTransferTask.transferID
        self.transferType = transferType
        self.sessionTask = sessionTask
        self.bucket = persistableTransferTask.bucket
        self.key = persistableTransferTask.key
        self.contentType = persistableTransferTask.contentType
        self.requestHeaders = persistableTransferTask.requestHeaders
        self.location = persistableTransferTask.location
        self.storageTransferDatabase = storageTransferDatabase
        self.logger = logger

        // set multiPartUpload with default value which can resume upload process
        if rawValue == .multiPartUpload,
           let uploadId = persistableTransferTask.uploadId,
           let uploadFile = persistableTransferTask.uploadFile {
            let multipartUpload = StorageMultipartUpload.created(uploadId: uploadId, uploadFile: uploadFile)
            self.uploadId = persistableTransferTask.uploadId
            self.multipartUpload = multipartUpload
        } else if rawValue == .multiPartUploadPart {
            self.uploadId = persistableTransferTask.uploadId
        }

        // this task is persisted by the db directly when instance is created
    }

    // Task Identifier is unique to each task in this instance of URLSession
    // and is used in the delegate functions to access the StorageTransferTask
    // which holds onto the URLSessionTask which is used here as well as the
    // onEvent handler to pass events back to the app.
    var taskIdentifier: TaskIdentifier? {
        sessionTask?.taskIdentifier
    }

    var isBelowRetryLimit: Bool {
        retryCount < retryLimit
    }

    private var cancelled: Bool {
        status == .cancelled
    }

    var isFailed: Bool {
        status == .error
    }

    func incrementRetryCount() {
        retryCount += 1
    }

    func notify(progress: Progress) {
        transferType.notify(progress: progress)
        status = .inProgress
    }

    func fail(error: Error) {
        guard status != .error else {
            logger.warn("Task is already failed: \(error)")
            return
        }
        transferType.fail(error: error)
        status = .error
        storageTransferDatabase.removeTransferRequest(task: self)
        proxyStorageTask = nil
    }

    func cancel() {
        guard status != .completed else {
            logger.warn("Unable to cancel when already completed")
            return
        }

        if let sessionTask = sessionTask {
            logger.debug("Cancelling storage transfer task: \(taskIdentifier ?? 0)")
            sessionTask.cancel()
            status = .cancelled
        } else if let proxyStorageTask = proxyStorageTask {
            logger.debug("Cancelling multipart upload: \(uploadId ?? "-")")
            proxyStorageTask.cancel()
            status = .cancelled
        } else {
            logger.warn("Session Task or Proxy Storage Task must be defined")
            return
        }

        storageTransferDatabase.removeTransferRequest(task: self)
        proxyStorageTask = nil
    }

    func resume() {
        guard status == .paused else {
            logger.debug("Unable to resume unless paused")
            return
        }

        if let sessionTask = sessionTask {
            logger.debug("Resuming storage transfer task: \(taskIdentifier ?? 0)")
            sessionTask.resume()
            status = .inProgress
        } else if let proxyStorageTask = proxyStorageTask {
            logger.debug("Resuming multipart upload: \(uploadId ?? "-")")
            proxyStorageTask.resume()
            status = .inProgress
        } else {
            logger.warn("Session Task or Proxy Storage Task must be defined")
            return
        }

        let reference = StorageTaskReference(self)
        switch transferType {
        case .download(let onEvent):
            onEvent(.initiated(reference))
        case .upload(let onEvent):
            onEvent(.initiated(reference))
        case .multiPartUpload(let onEvent):
            onEvent(.initiated(reference))
        default:
            fatalError("Unsupported transfer type: \(transferType.rawValue)")
        }

        storageTransferDatabase.updateTransferRequest(task: self)
    }

    func suspend() {
        guard status == .inProgress else {
            logger.debug("Unable to suspend unless in progress")
            return
        }
        
        if let sessionTask = sessionTask {
            logger.debug("Suspending storage transfer task: \(taskIdentifier ?? 0)")
            sessionTask.suspend()
            status = .paused
        } else if let proxyStorageTask = proxyStorageTask {
            logger.debug("Resuming multipart upload: \(uploadId ?? "-")")
            proxyStorageTask.pause()
            status = .paused
        } else {
            logger.warn("Session Task or Proxy Storage Task must be defined")
            return
        }

        storageTransferDatabase.updateTransferRequest(task: self)
    }

    func complete() {
        guard status != .cancelled else {
            logger.warn("Unable to complete after cancelled")
            return
        }
        guard status == .completed else {
            logger.warn("Task is already completed")
            return
        }

        logger.debug("Completing storage transfer task: \(taskIdentifier ?? 0)")

        status = .completed
        storageTransferDatabase.removeTransferRequest(task: self)
        proxyStorageTask = nil
    }
}

extension StorageTransferTask: StorageTask {
    func pause() {
        suspend()
    }
}

extension URLRequest {
    mutating func setHTTPRequestHeaders(transferTask: StorageTransferTask) {
        guard let requestHeaders = transferTask.requestHeaders else {
            return
        }

        requestHeaders.forEach { key, value in
            setValue(value, forHTTPHeaderField: key)
        }
    }
}
