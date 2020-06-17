//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

/// Convenience typealias defining a result publisher for Storage operations
public typealias StoragePublisher<Output> = AnyPublisher<Output, StorageError>

/// Encapsulates a result publisher and a progress publisher for operations that publish in-process updates, such as
/// uploads and downloads.
public struct StorageInProcessPublisher<Output> {
    /// Publishes progress updates for the associated operation. Completes when the `resultPublisher` receives a
    /// completion.
    public let progressPublisher: AnyPublisher<Progress, Never>

    /// Publishes an update with the result of an operation
    public let resultPublisher: StoragePublisher<Output>
}

public extension StorageCategoryBehavior {

    /// Retrieve an object from storage into memory
    ///
    /// - Parameters:
    ///   - key: The unique identifier for the object in storage
    ///   - options: Options to adjust the behavior of this request, including plugin-options
    /// - Returns: A StorageInProcessPublisher with the data of the downloaded object
    func downloadData(
        key: String,
        options: StorageDownloadDataOperation.Request.Options? = nil
    ) -> StorageInProcessPublisher<Data> {
        let progressSubject = PassthroughSubject<Progress, Never>()
        let progressPublisher = progressSubject.eraseToAnyPublisher()
        let progressListener: ProgressListener = {
            progressSubject.send($0)
        }
        let resultPublisher = Future<Data, StorageError> { promise in
            _ = self.downloadData(
                key: key,
                options: options,
                progressListener: progressListener
            ) {
                progressSubject.send(completion: .finished)
                promise($0)
            }
        }.eraseToAnyPublisher()

        return StorageInProcessPublisher(progressPublisher: progressPublisher, resultPublisher: resultPublisher)
    }

    /// Download the object from storage to a local file
    ///
    /// - Parameters:
    ///   - key: The unique identifier for the object in storage
    ///   - local: The local file to download the object to
    ///   - options: Parameters to specific plugin behavior
    /// - Returns: A StorageInProcessPublisher that completes when the file is downloaded
    func downloadFile(
        key: String,
        local: URL,
        options: StorageDownloadFileOperation.Request.Options? = nil
    ) -> StorageInProcessPublisher<Void> {
        let progressSubject = PassthroughSubject<Progress, Never>()
        let progressPublisher = progressSubject.eraseToAnyPublisher()
        let progressListener: ProgressListener = { progressSubject.send($0) }
        let resultPublisher = Future<Void, StorageError> { promise in
            _ = self.downloadFile(
                key: key,
                local: local,
                options: options,
                progressListener: progressListener
            ) {
                progressSubject.send(completion: .finished)
                promise($0)
            }
        }.eraseToAnyPublisher()

        return StorageInProcessPublisher(progressPublisher: progressPublisher, resultPublisher: resultPublisher)
    }

    /// Retrieve the remote URL for the object from storage
    ///
    /// - Parameters:
    ///   - key: The unique identifier for the object in storage
    ///   - options: Parameters to specific plugin behavior
    /// - Returns: A StoragePublisher with the URL of the object
    func getURL(
        key: String,
        options: StorageGetURLOperation.Request.Options? = nil
    ) -> StoragePublisher<URL> {
        Future { promise in
            _ = self.getURL(key: key, options: options) { promise($0) }
        }.eraseToAnyPublisher()
    }

    /// Lists the object identifiers under the heiarchy specified by the path, relative to access level, from storage
    ///
    /// - Parameters:
    ///   - options: Parameters to specific plugin behavior
    /// - Returns: A StoragePublisher with the list of objects
    func list(options: StorageListOperation.Request.Options? = nil) -> StoragePublisher<StorageListResult> {
        Future { promise in
            _ = self.list(options: options) { promise($0) }
        }.eraseToAnyPublisher()
    }

    /// Deletes an object from storage
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in storage
    ///   - options: Parameters to specific plugin behavior
    /// - Returns: A StoragePublisher that completes when the object is deleted
    func remove(
        key: String,
        options: StorageRemoveOperation.Request.Options? = nil
    ) -> StoragePublisher<String> {
        Future { promise in
            _ = self.remove(key: key, options: options) { promise($0) }
        }.eraseToAnyPublisher()
    }

    /// Upload data from memory to storage
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in storage
    ///   - data: The data in memory to be uploaded
    ///   - options: Parameters to specific plugin behavior
    /// - Returns: A StorageInProcessPublisher that completes when the data is uploaded
    func uploadData(
        key: String,
        data: Data,
        options: StorageUploadDataOperation.Request.Options? = nil
    ) -> StorageInProcessPublisher<String> {
        let progressSubject = PassthroughSubject<Progress, Never>()
        let progressPublisher = progressSubject.eraseToAnyPublisher()
        let progressListener: ProgressListener = { progressSubject.send($0) }
        let resultPublisher = Future<String, StorageError> { promise in
            _ = self.uploadData(
                key: key,
                data: data,
                options: options,
                progressListener: progressListener
            ) {
                progressSubject.send(completion: .finished)
                promise($0)
            }
        }.eraseToAnyPublisher()

        return StorageInProcessPublisher(progressPublisher: progressPublisher, resultPublisher: resultPublisher)
    }

    /// Uploads a local file to storage
    ///
    /// - Parameters:
    ///   - key: The unique identifier of the object in storage
    ///   - local: The path to a local file
    ///   - options: Parameters to specific plugin behavior
    /// - Returns: A StorageInProcessPublisher that completes when the file is uploaded
    func uploadFile(
        key: String,
        local: URL,
        options: StorageUploadFileOperation.Request.Options? = nil
    ) -> StorageInProcessPublisher<String> {
        let progressSubject = PassthroughSubject<Progress, Never>()
        let progressPublisher = progressSubject.eraseToAnyPublisher()
        let progressListener: ProgressListener = { progressSubject.send($0) }
        let resultPublisher = Future<String, StorageError> { promise in
            _ = self.uploadFile(
                key: key,
                local: local,
                options: options,
                progressListener: progressListener
            ) {
                progressSubject.send(completion: .finished)
                promise($0)
            }
        }.eraseToAnyPublisher()

        return StorageInProcessPublisher(progressPublisher: progressPublisher, resultPublisher: resultPublisher)
    }

}
