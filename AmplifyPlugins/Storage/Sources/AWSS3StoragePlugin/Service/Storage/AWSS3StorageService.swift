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

/// - Tag: AWSS3StorageService
class AWSS3StorageService: AWSS3StorageServiceBehaviour, StorageServiceProxy {

    // resettable values
    private var authService: AWSAuthServiceBehavior?
    var logger: Logger!
    var preSignedURLBuilder: AWSS3PreSignedURLBuilderBehavior!
    var awsS3: AWSS3Behavior!
    var region: String!
    var bucket: String!

    /// - Tag: AWSS3StorageService.s3Client
    @available(*, deprecated, renamed: "client")
    var s3Client: S3Client!

    /// - Tag: AWSS3StorageService.client
    var client: S3ClientProtocol

    let storageConfiguration: StorageConfiguration
    let sessionConfiguration: URLSessionConfiguration
    var delegateQueue: OperationQueue?
    var urlSession: URLSession
    let storageTransferDatabase: StorageTransferDatabase
    let fileSystem: FileSystem

    var tasks: [Int: StorageTransferTask] = [:]
    var multipartUploadSessions: [StorageMultipartUploadSession] = []

    private let serviceDispatchQueue = DispatchQueue(label: "com.amazon.aws.amplify.storage.service", target: .global())

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
        let credentialsProvider = authService.getCredentialsProvider()
        let clientConfig = try S3Client.S3ClientConfiguration(
            credentialsProvider: credentialsProvider,
            region: region,
            signingRegion: region)

        let s3Client = S3Client(config: clientConfig)
        let awsS3 = AWSS3Adapter(s3Client, config: clientConfig)
        let preSignedURLBuilder = AWSS3PreSignedURLBuilderAdapter(config: clientConfig, bucket: bucket)

        var _sessionConfiguration: URLSessionConfiguration
        if let sessionConfiguration = sessionConfiguration {
            _sessionConfiguration = sessionConfiguration
        } else {
            #if os(macOS)
            let sessionConfiguration = URLSessionConfiguration.default
            #else
            let sessionConfiguration = URLSessionConfiguration.background(withIdentifier: storageConfiguration.sessionIdentifier)
            #endif
            sessionConfiguration.urlCache = nil
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
         fileSystem: FileSystem = .default,
         sessionConfiguration: URLSessionConfiguration,
         delegateQueue: OperationQueue? = nil,
         logger: Logger = storageLogger,
         s3Client: S3Client,
         preSignedURLBuilder: AWSS3PreSignedURLBuilderBehavior,
         awsS3: AWSS3Behavior,
         bucket: String) {
        self.storageConfiguration = storageConfiguration
        self.storageTransferDatabase = storageTransferDatabase
        self.fileSystem = fileSystem
        self.sessionConfiguration = sessionConfiguration

        let delegate = StorageServiceSessionDelegate(identifier: storageConfiguration.sessionIdentifier, logger: logger)
        self.delegateQueue = delegateQueue
        self.urlSession = URLSession(configuration: sessionConfiguration, delegate: delegate, delegateQueue: delegateQueue)

        self.logger = logger
        self.s3Client = s3Client
        self.client = s3Client
        self.preSignedURLBuilder = preSignedURLBuilder
        self.awsS3 = awsS3
        self.bucket = bucket

        Task {
            await StorageBackgroundEventsRegistry.shared.register(identifier: identifier)
        }

        delegate.storageService = self

        storageTransferDatabase.recover(urlSession: urlSession) { [weak self] result in
            guard let self = self else { fatalError() }
            switch result {
            case .success(let pairs):
                logger.info("Recovery completed: [pairs = \(pairs.count)]")
                self.processTransferTaskPairs(pairs: pairs)
            case .failure(let error):
                logger.error(error: error)
            }
        }
    }

    deinit {
        Task {
            await StorageBackgroundEventsRegistry.shared.unregister(identifier: identifier)
        }
    }

    func reset() {
        authService = nil
        preSignedURLBuilder = nil
        awsS3 = nil
        region = nil
        bucket = nil
        tasks.removeAll()
        multipartUploadSessions.removeAll()
    }

    func resetURLSession() {
        let delegate = StorageServiceSessionDelegate(identifier: storageConfiguration.sessionIdentifier, logger: logger)
        self.urlSession = URLSession(configuration: sessionConfiguration, delegate: delegate, delegateQueue: delegateQueue)
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
                session.restart()
                register(multipartUploadSession: session)
            }
        }
    }

    func register(task: StorageTransferTask) {
        dispatchPrecondition(condition: .notOnQueue(serviceDispatchQueue))
        serviceDispatchQueue.sync {
            guard let taskIdentifier = task.taskIdentifier else { return }
            tasks[taskIdentifier] = task
        }
    }

    func unregister(task: StorageTransferTask) {
        dispatchPrecondition(condition: .notOnQueue(serviceDispatchQueue))
        serviceDispatchQueue.sync {
            guard let taskIdentifier = task.taskIdentifier else { return }
            tasks[taskIdentifier] = nil
        }
    }

    func unregister(taskIdentifiers: [TaskIdentifier]) {
        dispatchPrecondition(condition: .notOnQueue(serviceDispatchQueue))
        serviceDispatchQueue.sync {
            for taskIdentifier in taskIdentifiers {
                tasks[taskIdentifier] = nil
            }
        }
    }

    func register(multipartUploadSession: StorageMultipartUploadSession) {
        dispatchPrecondition(condition: .notOnQueue(serviceDispatchQueue))
        logger.debug("Registering multipart upload: \(multipartUploadSession.uploadId ?? "-")")
        serviceDispatchQueue.sync {
            multipartUploadSessions.append(multipartUploadSession)
        }
    }

    func unregister(multipartUploadSession: StorageMultipartUploadSession) {
        dispatchPrecondition(condition: .notOnQueue(serviceDispatchQueue))
        logger.debug("Unregistering multipart upload: \(multipartUploadSession.uploadId ?? "-")")
        serviceDispatchQueue.sync {
            guard let index = multipartUploadSessions.firstIndex(of: multipartUploadSession) else { return }
            multipartUploadSessions.remove(at: index)
        }
    }

    func findTask(taskIdentifier: TaskIdentifier) -> StorageTransferTask? {
        dispatchPrecondition(condition: .notOnQueue(serviceDispatchQueue))
        return serviceDispatchQueue.sync {
            let task = tasks[taskIdentifier]
            return task
        }
    }

    func findMultipartUploadSession(uploadId: UploadID) -> StorageMultipartUploadSession? {
        dispatchPrecondition(condition: .notOnQueue(serviceDispatchQueue))
        return serviceDispatchQueue.sync {
            let session = multipartUploadSessions.first { session in
                session.uploadId == uploadId
            }
            return session
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
            throw StorageError.validation("bucket", errorDescription, recoverySuggestion, nil)
        } else if key.isEmpty {
            let errorDescription = "Invalid key specified."
            let recoverySuggestion = "Please specify a key."
            throw StorageError.validation("key", errorDescription, recoverySuggestion, nil)
        }
    }

    func completeDownload(taskIdentifier: TaskIdentifier, sourceURL: URL) {
        guard let transferTask = findTask(taskIdentifier: taskIdentifier),
              case .download(let onEvent) = transferTask.transferType else {
                  logger.info("Unable to complete download for task: \(taskIdentifier)")
                  return
              }

        // When a location is provided the downloaded file could be moved there.
        // Otherwise the Data can be returned on the completed result.

        let data: Data?
        do {
            if let destinationLocation = transferTask.location {
                try fileSystem.moveFile(from: sourceURL, to: destinationLocation)
                data = nil
            } else {
                data = try Data(contentsOf: sourceURL)
            }
            onEvent(.completed(data))
            transferTask.complete()
        } catch {
            data = nil
            transferTask.fail(error: error)
        }
    }

}
