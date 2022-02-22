//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

// swiftlint:disable line_length

/// Default database implementation for ``StorageTransferDatabase`` protocol.
class DefaultStorageTransferDatabase {
    enum Failure: Error {
        case notExists(fileURL: URL)
        case noData(fileURL: URL)
    }

    enum RecoveryState {
        case notStarted
        case inProgress
        case completed
    }

    private let queue = DispatchQueue(label: "com.amazon.aws.amplify.storage", qos: .background, target: .global())
    private let fileSystem: FileSystem
    private let logger: Logger

    private let databaseDirectoryURL: URL
    private var tasks: [TransferID: StorageTransferTask] = [:]
    private var recoveryState: RecoveryState = .notStarted

    var tasksCount: Int {
        tasks.values.count
    }

    private var uploadEventHandler: AWSS3StorageServiceBehaviour.StorageServiceUploadEventHandler?
    private var downloadEventHandler: AWSS3StorageServiceBehaviour.StorageServiceDownloadEventHandler?
    private var multipartUploadEventHandler: AWSS3StorageServiceBehaviour.StorageServiceMultiPartUploadEventHandler?

    static let `default`: StorageTransferDatabase = {
        DefaultStorageTransferDatabase()
    }()

    init(databaseDirectoryURL: URL? = nil, fileSystem: FileSystem = .default, logger: Logger = storageLogger) {
        self.fileSystem = fileSystem
        self.logger = logger

        self.databaseDirectoryURL = databaseDirectoryURL ?? fileSystem.documentsURL
            .appendingPathComponent("Storage", isDirectory: true)
            .appendingPathComponent("TransferTasks", isDirectory: true)

        // ensure database directory exists
        try? fileSystem.createDirectory(at: self.databaseDirectoryURL)

        // TODO: remove files which are more than a week old

        // TODO: observe application state changes to trigger call to prepareForBackground
    }

    func recover(urlSession: StorageURLSession = URLSession.shared,
                 completionHandler: @escaping (Result<StorageTransferTaskPairs, Error>) -> Void) {
        queue.async { [weak self] in
            guard let self = self else { fatalError("self cannot be weak") }
            self.loadTasksAndLinkSessions(urlSession: urlSession, completionHandler: completionHandler)
        }
    }

    func linkTasksWithSessions(persistableTransferTasks: [TransferID: StoragePersistableTransferTask],
                               sessionTasks: StorageSessionTasks) -> StorageTransferTaskPairs {
        let transferTasks: [StorageTransferTask] = persistableTransferTasks.reduce(into: []) { tasks, pair in
            // match sessionTask to persistableTransferTask with taskIdentifier
            let persistableTransferTask = pair.value
            if let taskIdentifier = persistableTransferTask.taskIdentifier,
               let transferType = defaultTransferType(persistableTransferTask: persistableTransferTask),
               let sessionTask = sessionTasks.first(where: { $0.taskIdentifier == taskIdentifier}) {
                let transferTask = StorageTransferTask(persistableTransferTask: persistableTransferTask,
                                                       transferType: transferType,
                                                       sessionTask: sessionTask,
                                                       storageTransferDatabase: self,
                                                       logger: logger)
                tasks.append(transferTask)
            } else if persistableTransferTask.transferTypeRawValue == StorageTransferType.RawValues.multiPartUpload.rawValue,
                      let transferType = defaultTransferType(persistableTransferTask: persistableTransferTask) {
                let transferTask = StorageTransferTask(persistableTransferTask: persistableTransferTask,
                                                       transferType: transferType,
                                                       storageTransferDatabase: self,
                                                       logger: logger)
                tasks.append(transferTask)
            }
        }

        // Tasks grouped by uploadId to collect sub tasks for multipart uploads.
        let grouped: [UploadID: StoragePersistableTransferTasks] = persistableTransferTasks.values.reduce(into: [:]) { dictionary, task in
            guard let uploadId = task.uploadId else { return }
            if dictionary[uploadId] != nil {
                dictionary[uploadId]?.append(task)
            } else {
                dictionary[uploadId] = [task]
            }
        }

        let multipartUploads: [StorageMultipartUpload] = grouped.compactMap { pair in
            guard let mainTask = pair.value.first(where: { $0.uploadId != nil &&  $0.partNumber == nil }),
                  let multipartUpload = mainTask.multipartUpload,
                  let partSize = try? StorageUploadPartSize(fileSize: multipartUpload.size),
                  var parts = try? StorageUploadParts(fileSize: multipartUpload.size, partSize: partSize, logger: self.logger),
                  parts.count > 1 else {
                      return nil
                  }

            let uploadId = pair.key
            let uploadFile = UploadFile(multipartUpload: multipartUpload)

            let subTasks = pair.value.filter { $0.partNumber != nil }.compactMap {
                $0.subTask
            }

            // all parts are defaulted to pending
            subTasks.enumerated().forEach { index, subTask in
                guard subTask.partNumber <= parts.count, subTask.partNumber > 0 else { return }
                let index = subTask.partNumber - 1

                if let taskIdentifier = subTask.taskIdentifier {
                    parts[index] = .inProgress(bytes: subTask.bytes, bytesTransferred: subTask.bytesTransferred, taskIdentifier: taskIdentifier)
                } else if let eTag = subTask.eTag {
                    parts[index] = .completed(bytes: subTask.bytes, eTag: eTag)
                }
            }

            return StorageMultipartUpload.parts(uploadId: uploadId, uploadFile: uploadFile, partSize: partSize, parts: parts)
        }

        // create pairs to pass back for processing by Storage Service
        let pairs = transferTasks.map { transferTask in
            StorageTransferTaskPair(transferTask: transferTask, multipartUploads: multipartUploads)
        }

        return pairs
    }

    func loadPersistableTasks() -> [TaskIdentifier: StoragePersistableTransferTask] {
        let persistableTransferTasks: [TaskIdentifier: StoragePersistableTransferTask] = loadTasks().reduce(into: [:]) { dictionary, item in
            if let taskIdentifier = item.value.taskIdentifier ?? item.value.subTask?.taskIdentifier {
                dictionary[taskIdentifier] = item.value
            }
        }
        return persistableTransferTasks
    }

    private func loadTasksAndLinkSessions(urlSession: StorageURLSession = URLSession.shared,
                                          completionHandler: @escaping (Result<StorageTransferTaskPairs, Error>) -> Void) {
        dispatchPrecondition(condition: .notOnQueue(.main))
        dispatchPrecondition(condition: .onQueue(queue))

        guard recoveryState == .notStarted else { return }

        recoveryState = .inProgress

        let persistableTransferTasks = loadTasks()

        // A StorageTransferTask has a computed property for taskIdentifier which comes from the underlying sessionTask
        // which is not persisted and must be linked with the instance from URLSession to access that value again.
        // This value is used to associate delegate method calls with StorageTransferTask which holds onto the onEvent
        // closure to send events back to the app.

        // A MultipartUpload is different because it starts with a create request to get the uploadId which is used by
        // a series of sub tasks which are uploads which will have a sessionTask and a taskIdentifier. It is necessary
        // to also link these task so that delegate methods send events into StorageMultipartUploadSession to update
        // the lifecycle so that the process can be completed.

        let sessionTaskHandler: (StorageSessionTasks) -> Void = { [weak self] sessionTasks in
            guard let self = self else { fatalError("self cannot be weak") }

            let pairs = self.linkTasksWithSessions(persistableTransferTasks: persistableTransferTasks, sessionTasks: sessionTasks)
            completionHandler(.success(pairs))
            self.recoveryState = .completed
        }

        urlSession.getActiveTasks(resultHandler: sessionTaskHandler)
    }

    func storeTasks() throws {
        dispatchPrecondition(condition: .notOnQueue(.main))
        dispatchPrecondition(condition: .onQueue(queue))

        for task in tasks.values {
            try storeTask(task: task)
        }
    }

    func loadTasks() -> [TransferID: StoragePersistableTransferTask] {
        dispatchPrecondition(condition: .notOnQueue(.main))
        dispatchPrecondition(condition: .onQueue(queue))

        let tasks = try? fileSystem.directoryContents(directoryURL: databaseDirectoryURL) {
            $0.hasSuffix(".json")
        }.compactMap { fileURL -> StoragePersistableTransferTask? in
            try? loadTask(fileURL: fileURL)
        }.reduce(into: [:]) { dictionary, task in
            dictionary[task.transferID] = task
        }

        return tasks ?? [:]
    }

    // ~/Documents/Storage/TransferTasks/(TransferID).json
    func getFileURL(for transferID: TransferID) -> URL {
        let fileURL = databaseDirectoryURL
            .appendingPathComponent(transferID, isDirectory: false)
            .appendingPathExtension("json")
        return fileURL
    }

    @discardableResult
    func storeTask(task: StorageTransferTask) throws -> URL {
        let fileURL = getFileURL(for: task.transferID)
        let value = StoragePersistableTransferTask(task: task)
        try store(fileURL: fileURL, value: value)
        return fileURL
    }

    func loadTask(fileURL: URL) throws -> StoragePersistableTransferTask {
        try load(fileURL: fileURL, type: StoragePersistableTransferTask.self)
    }

    private func handleUploadEvent(event: AWSS3StorageServiceBehaviour.StorageServiceUploadEvent) {
        uploadEventHandler?(event)
    }

    private func handleDownloadEvent(event: AWSS3StorageServiceBehaviour.StorageServiceDownloadEvent) {
        downloadEventHandler?(event)
    }

    private func handleMultipartUploadEvent(event: AWSS3StorageServiceBehaviour.StorageServiceMultiPartUploadEvent) {
        multipartUploadEventHandler?(event)
    }

    private func load<T>(fileURL: URL, type: T.Type) throws -> T where T: Decodable {
        if Thread.isMainThread {
            logger.warn("Loading on main thread")
        }

        if !fileSystem.fileExists(atURL: fileURL) {
            // No data has been stored yet or it was deleted
            throw Failure.notExists(fileURL: fileURL)
        }
        guard let jsonData = fileSystem.contents(atURL: fileURL) else {
            // automatically delete an invalid file
            fileSystem.removeFileIfExists(fileURL: fileURL)
            throw Failure.noData(fileURL: fileURL)
        }
        let instance = try JSONDecoder().decode(type.self, from: jsonData)
        return instance
    }

    private func store<T>(fileURL: URL, value: T) throws  where T: Encodable {
        if Thread.isMainThread {
            logger.warn("Storing on main thread")
        }

        do {
            let jsonData = try JSONEncoder().encode(value)
            // clear a file if it is in the way
            fileSystem.removeFileIfExists(fileURL: fileURL)
            try jsonData.write(to: fileURL)
        } catch {
            print("Error: \(error)")
            throw error
        }
    }

}

extension DefaultStorageTransferDatabase: StorageTransferDatabase {

    func insertTransferRequest(task: StorageTransferTask) {
        dispatchPrecondition(condition: .notOnQueue(queue))
        queue.sync {
            tasks[task.transferID] = task
        }
    }

    func updateTransferRequest(task: StorageTransferTask) {
        dispatchPrecondition(condition: .notOnQueue(queue))
        queue.sync {
            tasks[task.transferID] = task
        }
    }

    func removeTransferRequest(task: StorageTransferTask) {
        dispatchPrecondition(condition: .notOnQueue(queue))
        queue.sync {
            tasks[task.transferID] = nil
        }
    }

    func prepareForBackground(completion: (() -> Void)? = nil) {
        dispatchPrecondition(condition: .notOnQueue(queue))
        queue.async { [weak self] in
            guard let self = self else { fatalError("self cannot be weak") }
            do {
                try self.storeTasks()
            } catch {
                self.logger.error(error: error)
            }
            completion?()
        }
    }

    func defaultTransferType(persistableTransferTask: StoragePersistableTransferTask) -> StorageTransferType? {
        guard let rawValue = StorageTransferType.RawValues(rawValue: persistableTransferTask.transferTypeRawValue) else {
            logger.warn("Invalid transfer type: \(persistableTransferTask.transferTypeRawValue)")
            return nil
        }

        let transferType: StorageTransferType?
        switch rawValue {
        case .download:
            transferType = .download(onEvent: handleDownloadEvent(event:))
        case .upload:
            transferType = .upload(onEvent: handleUploadEvent)
        case .multiPartUpload:
            transferType = .multiPartUpload(onEvent: handleMultipartUploadEvent(event:))
        case .multiPartUploadPart:
            if let uploadId = persistableTransferTask.uploadId, let partNumber = persistableTransferTask.partNumber {
                transferType = .multiPartUploadPart(uploadId: uploadId, partNumber: partNumber)
            } else {
                transferType = nil
            }
        default:
            if let defaultTransferType = StorageTransferType.Defaults.createDefaultTransferType(persistableTransferTask: persistableTransferTask) {
                transferType = defaultTransferType
            } else {
                logger.warn("Invalid transfer type: \(persistableTransferTask.transferTypeRawValue)")
                transferType = nil
            }
        }
        return transferType
    }

    func attachEventHandlers(onUpload: AWSS3StorageServiceBehaviour.StorageServiceUploadEventHandler?,
                             onDownload: AWSS3StorageServiceBehaviour.StorageServiceDownloadEventHandler?,
                             onMultipartUpload: AWSS3StorageServiceBehaviour.StorageServiceMultiPartUploadEventHandler?) {
        queue.async { [weak self] in
            guard let self = self else { fatalError("self cannot be weak") }
            self.uploadEventHandler = onUpload
            self.downloadEventHandler = onDownload
            self.multipartUploadEventHandler = onMultipartUpload
        }
    }
}

extension StorageTransferDatabase where Self == DefaultStorageTransferDatabase {

    static var `default`: StorageTransferDatabase {
        DefaultStorageTransferDatabase.default
    }

}

extension StorageTransferDatabase {

    static var `default`: StorageTransferDatabase {
        DefaultStorageTransferDatabase.default
    }
}
