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
    typealias Action = () -> Void

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
    private let taskQueue = DispatchQueue(label: "com.amazon.aws.amplify.storage-transfer-task", target: .global())
    private var _status: StorageTransferStatus = .unknown
    internal private(set) var status: StorageTransferStatus {
        get {
            dispatchPrecondition(condition: .notOnQueue(taskQueue))
            return taskQueue.sync {
                _status
            }
        }
        set {
            dispatchPrecondition(condition: .notOnQueue(taskQueue))
            taskQueue.sync {
                _status = newValue
            }
        }
    }

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
        taskQueue.sync {
            sessionTask?.taskIdentifier
        }
    }

    var isBelowRetryLimit: Bool {
        taskQueue.sync {
            retryCount < retryLimit
        }
    }

    private var cancelled: Bool {
        status == .cancelled
    }

    var isFailed: Bool {
        status == .error
    }

    func incrementRetryCount() {
        taskQueue.sync {
            retryCount += 1
        }
    }

    func notify(progress: Progress) {
        taskQueue.sync {
            transferType.notify(progress: progress)
            _status = .inProgress
        }
    }

    func fail(error: Error) {
        taskQueue.sync {
            guard _status != .error else {
                logger.warn("Task is already failed: \(error)")
                return
            }
            transferType.fail(error: error)
            _status = .error
            storageTransferDatabase.removeTransferRequest(task: self)
            proxyStorageTask = nil
        }
    }

    func cancel() {
        let action: Action? = taskQueue.sync {
            let action: Action?
            guard _status != .completed else {
                logger.warn("Unable to cancel when already completed")
                return nil
            }

            if let sessionTask = sessionTask {
                logger.debug("Cancelling storage transfer task: \(sessionTask.taskIdentifier)")
                action = {
                    sessionTask.cancel()
                }
                _status = .cancelled
            } else if let proxyStorageTask = proxyStorageTask {
                logger.debug("Cancelling multipart upload: \(uploadId ?? "-")")
                action = {
                    proxyStorageTask.cancel()
                }
                _status = .cancelled
            } else {
                logger.warn("Session Task or Proxy Storage Task must be defined")
                action = nil
                return action
            }

            storageTransferDatabase.removeTransferRequest(task: self)
            proxyStorageTask = nil
            return action
        }
        action?()
    }

    func resume() {
        let action: Action? = taskQueue.sync {
            let action: Action?
            guard _status == .paused else {
                logger.debug("Unable to resume unless paused")
                return nil
            }

            if let sessionTask = sessionTask {
                logger.debug("Resuming storage transfer task: \(sessionTask.taskIdentifier)")
                action = {
                    sessionTask.resume()
                }
                _status = .inProgress
            } else if let proxyStorageTask = proxyStorageTask {
                logger.debug("Resuming multipart upload: \(uploadId ?? "-")")
                action = {
                    proxyStorageTask.resume()
                }
                _status = .inProgress
            } else {
                logger.warn("Session Task or Proxy Storage Task must be defined")
                action = nil
                return action
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
            return action
        }
        action?()
    }

    func suspend() {
        let action: Action? = taskQueue.sync {
            let action: Action?
            guard _status == .inProgress else {
                logger.debug("Unable to suspend unless in progress")
                return nil
            }

            if let sessionTask = sessionTask {
                logger.debug("Suspending storage transfer task: \(sessionTask.taskIdentifier)")
                action = {
                    sessionTask.suspend()
                }
                _status = .paused
            } else if let proxyStorageTask = proxyStorageTask {
                logger.debug("Resuming multipart upload: \(uploadId ?? "-")")
                action = {
                    proxyStorageTask.pause()
                }
                _status = .paused
            } else {
                logger.warn("Session Task or Proxy Storage Task must be defined")
                action = nil
                return action
            }

            storageTransferDatabase.updateTransferRequest(task: self)
            return action
        }
        action?()
    }

    func complete() {
        taskQueue.sync {
            guard _status != .cancelled else {
                logger.warn("Unable to complete after cancelled")
                return
            }
            guard _status == .completed else {
                logger.warn("Task is already completed")
                return
            }

            if let sessionTask = sessionTask {
                logger.debug("Completing storage transfer task: \(sessionTask.taskIdentifier)")
            }

            _status = .completed
            storageTransferDatabase.removeTransferRequest(task: self)
            proxyStorageTask = nil
        }
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
