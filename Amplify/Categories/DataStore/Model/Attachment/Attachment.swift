//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

private func getDocumentPath() -> URL? {
    return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
}

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
    
    // MARK: - save
    
    public func save() async throws -> URL {
        guard let metadata = metadata else {
            throw StorageError.validation("Metadata", "Missing metadata", "", nil)
        }
        switch state {
        case .data(let data):
            let path = metadata.accessLevel ?? "public"
            
            let url = getFilePath(path: path, key: metadata.key)
            do {
                print("Saving to \(url)")
                try data.write(to: url)
            } catch {
                print(error)
            }
            return url
        case .file(let file):
            return file
        case .empty:
            throw StorageError.validation("Metadata", "No data or file to upload", "", nil)
        }
    }
    public func save(_ completion: @escaping DataStoreCallback<URL>) {
        Task {
            do {
                let url = try await save()
                completion(Result<URL, DataStoreError>.success(url))
            } catch {
                completion(.failure(DataStoreError.internalOperation("Attachment Save failed", "", error)))
            }
        }
    }
    
    func getFilePath(path: String, key: String) -> URL {
        guard let documentsPath = getDocumentPath() else {
            return Fatal.preconditionFailure("Could not create the database. The `.documentDirectory` is invalid")
        }
        let folderURL = documentsPath.appendingPathComponent("\(path)/")
        if !FileManager.default.fileExists(atPath: folderURL.path) {
            do {
                try FileManager.default.createDirectory(atPath: folderURL.path, withIntermediateDirectories: true, attributes: nil)
            }
            catch {}
        }
        let fileURL = folderURL.appendingPathComponent("\(key)")
        return fileURL
    }
    
    // MARK: - Upload
    
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
    
    public func uploadFile(_ file: URL) async throws -> StorageUploadFileTask {
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
    
    public func removeFile() throws {
        guard let metadata = metadata else {
            throw StorageError.validation("Metadata", "Missing metadata", "", nil)
        }
        let path = metadata.accessLevel ?? "public"
        let url = getFilePath(path: path, key: metadata.key)
        try FileManager.default.removeItem(at: url)
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
        let path = metadata.accessLevel ?? "public"
        let url = getFilePath(path: path, key: metadata.key)
        if FileManager.default.fileExists(atPath: url.path) {
            print("FILE EXISTS, returning immedaitely")
            return url
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
