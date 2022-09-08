//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public class Attachment<Metadata: EmbeddableAttachment>: Codable, AttachmentBehavior {
    
    enum AttachedState {
        case data(Data)
        case file(URL)
        case empty
    }
    
    public var metadata: Metadata?
    var state: AttachedState
    
    required public init(_ metadata: Metadata?) {
        self.metadata = metadata
        self.state = .empty
    }
    
    
    public func attachData(_ data: Data) {
        self.state = .data(data)
    }
    public func attachFile(_ file: URL) {
        self.state = .file(file)
    }
    
    public func upload() async throws -> String {
        guard let metadata = metadata else {
            throw StorageError.validation("Metadata", "Missing metadata", "", nil)
        }
        switch state {
        case .data(let data):
            let options = StorageUploadDataRequest.Options(accessLevel: .guest)
            let uploadDataRequest = StorageUploadDataRequest(key: metadata.key, data: data, options: options)
            return try await upload(uploadDataRequest)
        case .file(let file):
            let options = StorageUploadFileRequest.Options(accessLevel: .guest)
            let uploadFileRequest = StorageUploadFileRequest(key: metadata.key, local: file, options: options)
            return try await upload(uploadFileRequest)
        case .empty:
            throw StorageError.validation("Metadata", "No data or file to upload", "", nil)
        }
    }
    
    public func uploadData(_ data: Data) async throws -> StorageUploadDataTask {
        guard let metadata = metadata else {
            throw StorageError.validation("Metadata", "Missing metadata", "", nil)
        }
        attachData(data)
        let options = StorageUploadDataRequest.Options(accessLevel: .guest)
        let request = StorageUploadDataRequest(key: metadata.key, data: data, options: options)
        return try await Amplify.Storage.uploadData(key: request.key,
                                                        data: request.data,
                                                        options: request.options)
    }
    
    func uploadFile(_ file: URL) async throws -> StorageUploadFileTask {
        guard let metadata = metadata else {
            throw StorageError.validation("Metadata", "Missing metadata", "", nil)
        }
        attachFile(file)
        let options = StorageUploadFileRequest.Options(accessLevel: .guest)
        let request = StorageUploadFileRequest(key: metadata.key, local: file, options: options)
        return try await Amplify.Storage.uploadFile(key: request.key,
                                                      local: request.local,
                                                      options: request.options)
    }
    
    public func downloadData() async throws -> StorageDownloadDataTask {
        guard let metadata = metadata else {
            throw StorageError.validation("Metadata", "Missing metadata", "", nil)
        }
        let options = StorageDownloadDataRequest.Options(accessLevel: .guest)
        return try await Amplify.Storage.downloadData(key: metadata.key, options: options)
    }
    
    public func downloadFile(to local: URL) async throws -> StorageDownloadFileTask {
        guard let metadata = metadata else {
            throw StorageError.validation("Metadata", "Missing metadata", "", nil)
        }
        let options = StorageDownloadFileRequest.Options(accessLevel: .guest)
        return try await Amplify.Storage.downloadFile(key: metadata.key, local: local, options: options)
    }
    
    public func remove() async throws {
        guard let metadata = metadata else {
            throw StorageError.validation("Metadata", "Missing metadata", "", nil)
        }
        let options = StorageRemoveRequest.Options(accessLevel: .guest)
        _ = try await Amplify.Storage.remove(key: metadata.key, options: options)
    }
    
    public func getURL() async throws -> URL {
        guard let metadata = metadata else {
            throw StorageError.validation("Metadata", "Missing metadata", "", nil)
        }
        let options = StorageGetURLRequest.Options(accessLevel: .guest)
        return try await Amplify.Storage.getURL(key: metadata.key, options: options)
    }
    
    
    // MARK: - Upload
    
    func upload(_ request: StorageUploadDataRequest) async throws -> String {
        do {
            let task = try await Amplify.Storage.uploadData(key: request.key,
                                                            data: request.data,
                                                            options: request.options)
            Task {
                for await progress in await task.inProcess {
                    print("progress \(progress)")
                }
            }
            return try await task.value
        } catch {
            print("Failed with error \(error)")
            throw error
        }
    }
    
    func upload(_ request: StorageUploadFileRequest) async throws -> String {
        do {
            let task = try await Amplify.Storage.uploadFile(key: request.key,
                                                            local: request.local,
                                                            options: request.options)
            Task {
                for await progress in await task.inProcess {
                    print("progress \(progress)")
                }
            }
            return try await task.value
        } catch {
            print("Failed with error \(error)")
            throw error
        }
    }
    
    
    // MARK: - Custom Decoder
    
    required public convenience init(from decoder: Decoder) throws {
        let metadata = try Metadata(from: decoder)
        self.init(metadata)
    }
    
    public func encode(to encoder: Encoder) throws {
        try metadata.encode(to: encoder)
    }
}
