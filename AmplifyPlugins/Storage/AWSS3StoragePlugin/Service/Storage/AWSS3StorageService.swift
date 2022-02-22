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

class AWSS3StorageService: AWSS3StorageServiceBehaviour, StorageBackgroundEventsHandler, StorageServiceProxy {

    // resettable values
    private var authService: AWSAuthServiceBehavior?
    var logger: Logger!
    var preSignedURLBuilder: AWSS3PreSignedURLBuilderBehavior!
    var awsS3: AWSS3Behavior!
    var region: String!
    var bucket: String!

    var s3Client: S3Client!

    let storageConfiguration: StorageConfiguration
    let sessionConfiguration: URLSessionConfiguration
    let urlSession: URLSession
    let storageTransferDatabase: StorageTransferDatabase

    var tasks: [Int: StorageTransferTask] = [:]
    var multipartUploadSessions: [StorageMultipartUploadSession] = []

    var backgroundEventCompletionHandler: (() -> Void)?

    var identifier: String {
        storageConfiguration.sessionIdentifier
    }

    convenience init(authService: AWSAuthServiceBehavior,
         region: String,
         bucket: String,
         storageConfiguration: StorageConfiguration = .default,
         storageTransferDatabase: StorageTransferDatabase = .default,
         sessionConfiguration: URLSessionConfiguration? = nil,
         delegateQueue: OperationQueue? = nil,
         logger: Logger = storageLogger) throws {

        let s3Client = try S3Client(region: region)
        let awsS3 = AWSS3Adapter(s3Client)
        let preSignedURLBuilder = try AWSS3PreSignedURLBuilderAdapter(region: region, bucket: bucket)

        var _sessionConfiguration: URLSessionConfiguration
        if let sessionConfiguration = sessionConfiguration {
            _sessionConfiguration = sessionConfiguration
        } else {
            let identifier = storageConfiguration.sessionIdentifier
            let sessionConfiguration = URLSessionConfiguration.background(withIdentifier: identifier)
            sessionConfiguration.allowsCellularAccess = storageConfiguration.allowsCellularAccess
            sessionConfiguration.timeoutIntervalForResource = TimeInterval(storageConfiguration.timeoutIntervalForResource)
            _sessionConfiguration = sessionConfiguration
        }

        _sessionConfiguration.sharedContainerIdentifier = storageConfiguration.sharedContainerIdentifier

        self.init(authService: authService,
                  storageConfiguration: storageConfiguration,
                  storageTransferDatabase: storageTransferDatabase,
                  sessionConfiguration: _sessionConfiguration,
                  s3Client: s3Client,
                  preSignedURLBuilder: preSignedURLBuilder,
                  awsS3: awsS3,
                  bucket: bucket)
    }

    init(authService: AWSAuthServiceBehavior,
         storageConfiguration: StorageConfiguration = .default,
         storageTransferDatabase: StorageTransferDatabase = .default,
         sessionConfiguration: URLSessionConfiguration,
         delegateQueue: OperationQueue? = nil,
         logger: Logger = storageLogger,
         s3Client: S3Client,
         preSignedURLBuilder: AWSS3PreSignedURLBuilderBehavior,
         awsS3: AWSS3Behavior,
         bucket: String) {

        self.storageConfiguration = storageConfiguration
        self.storageTransferDatabase = storageTransferDatabase
        self.sessionConfiguration = sessionConfiguration

        let delegate = StorageServiceSessionDelegate(identifier: storageConfiguration.sessionIdentifier, logger: logger)
        self.urlSession = URLSession(configuration: sessionConfiguration, delegate: delegate, delegateQueue: delegateQueue)

        self.logger = logger
        self.s3Client = s3Client
        self.preSignedURLBuilder = preSignedURLBuilder
        self.awsS3 = awsS3
        self.bucket = bucket

        StorageRegistry.register(identifier: identifier, backgroundEventsHandler: self)

        delegate.storageService = self

        storageTransferDatabase.recover(urlSession: urlSession) { [weak self] result in
            guard let self = self else { fatalError() }
            switch result {
            case .success(let pairs):
                logger.info("Recovery completed: [pairs = '\(pairs.count)]")
                self.processTransferTaskPairs(pairs: pairs)
            case .failure(let error):
                logger.error(error: error)
            }
        }
    }

    deinit {
        StorageRegistry.unregister(identifier: identifier)
    }

    func reset() {
        authService = nil
        logger = nil
        preSignedURLBuilder = nil
        awsS3 = nil
        region = nil
        bucket = nil
    }

    func attachEventHandlers(onUpload: AWSS3StorageServiceBehaviour.StorageServiceUploadEventHandler? = nil,
                             onDownload: AWSS3StorageServiceBehaviour.StorageServiceDownloadEventHandler? = nil,
                             onMultipartUpload: AWSS3StorageServiceBehaviour.StorageServiceMultiPartUploadEventHandler? = nil) {
        storageTransferDatabase.attachEventHandlers(onUpload: onUpload, onDownload: onDownload, onMultipartUpload: onMultipartUpload)
    }

    private func processTransferTaskPairs(pairs: StorageTransferTaskPairs) {
        for pair in pairs {
            register(task: pair.transferTask)
            if let multipartUpload = pair.multipartUpload,
               let uploadFile = multipartUpload.uploadFile {
                let client = DefaultStorageMultipartUploadClient(serviceProxy: self,
                                                                 bucket: pair.transferTask.bucket,
                                                                 key: pair.transferTask.key,
                                                                 uploadFile: uploadFile)
                guard let session = StorageMultipartUploadSession(client: client, transferTask: pair.transferTask, multipartUpload: multipartUpload, logger: logger) else {
                    return
                }
                session.resume()
                register(multipartUploadSession: session)
            }
        }
    }

    func register(task: StorageTransferTask) {
        guard let taskIdentifier = task.taskIdentifier else { return }
        tasks[taskIdentifier] = task
    }

    func unregister(task: StorageTransferTask) {
        guard let taskIdentifier = task.taskIdentifier else { return }
        tasks[taskIdentifier] = nil
    }

    func register(multipartUploadSession: StorageMultipartUploadSession) {
        multipartUploadSessions.append(multipartUploadSession)
    }

    func unregister(multipartUploadSession: StorageMultipartUploadSession) {
        guard let index = multipartUploadSessions.firstIndex(of: multipartUploadSession) else { return }
        multipartUploadSessions.remove(at: index)
    }

    func findTask(taskIdentifier: TaskIdentifier) -> StorageTransferTask? {
        let task = tasks[taskIdentifier]

        return task
    }

    // TODO: determine if this function is needed for recovery
    func linkTransfers() {
        urlSession.getTasksWithCompletionHandler { [weak self] _, uploadTasks, downloadTasks in
            guard let self = self else { return }
            uploadTasks.forEach { uploadTask in
                self.logger.debug("Linking upload task for identifier: \(uploadTask.taskIdentifier)")
            }
            downloadTasks.forEach { downloadTask in
                self.logger.debug("Linking download task for identifier: \(downloadTask.taskIdentifier)")
            }
        }
    }

    func createTransferTask(transferType: StorageTransferType,
                            bucket: String,
                            key: String,
                            location: URL? = nil,
                            requestHeaders: [String: String]? = nil) -> StorageTransferTask {
        let transferTask = StorageTransferTask(transferType: transferType,
                                               bucket: bucket,
                                               key: key,
                                               location: location,
                                               requestHeaders: requestHeaders,
                                               storageTransferDatabase: storageTransferDatabase,
                                               logger: logger)
        return transferTask
    }

    func validateParameters(bucket: String, key: String, accelerationModeEnabled: Bool) throws {
        if bucket.isEmpty {
            let errorDescription = "Invalid bucket specified."
            let recoverySuggestion = "Please specify a bucket name or configure the bucket property."
            throw accelerationModeEnabled ?
            StorageError.invalidBucketNameForAccelerateModeEnabled(errorDescription, "", nil) :
            StorageError.invalidBucket(errorDescription, recoverySuggestion, nil)
        } else if key.isEmpty {
            let errorDescription = "Invalid key specified."
            let recoverySuggestion = "Please specify a key."
            throw StorageError.invalidKey(errorDescription, recoverySuggestion, nil)
        }
    }

}

class StorageServiceSessionDelegate: NSObject {
    let identifier: String
    let logger: Logger
    weak var storageService: AWSS3StorageService?

    init(identifier: String, logger: Logger = storageLogger) {
        self.identifier = identifier
        self.logger = logger
    }

    private func findTransferTask(for taskIdentifier: TaskIdentifier) -> StorageTransferTask? {
        guard let storageService = storageService,
              let transferTask = storageService.findTask(taskIdentifier: taskIdentifier) else {
                  logger.error("Failed to find transfer task: \(taskIdentifier)")
                  return nil
              }
        return transferTask
    }
}

public extension Notification.Name {
    static let StorageURLSessionDidBecomeInvalidNotification = Notification.Name("URLSessionDidBecomeInvalidNotification")
    static let reachabilityChanged = Notification.Name("reachabilityChanged")
}

extension StorageServiceSessionDelegate: URLSessionDelegate {

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        #warning("Not Implemented")
        fatalError("Not Implemented")
    }

    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        #warning("Not Implemented")
        fatalError("Not Implemented")
    }
}

extension StorageServiceSessionDelegate: URLSessionTaskDelegate {

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        #warning("Not Implemented")
        fatalError("Not Implemented")
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        #warning("Not Implemented")
        fatalError("Not Implemented")
    }

}

extension StorageServiceSessionDelegate: URLSessionDownloadDelegate {

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        #warning("Not Implemented")
        fatalError("Not Implemented")
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        #warning("Not Implemented")
        fatalError("Not Implemented")
    }

}
