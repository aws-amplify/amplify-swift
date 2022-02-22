//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// swiftlint:disable line_length
/// File System implementation which wraps FileManager.
///
/// An abstraction to simplify interactions with the filesystem.
///
/// ## Important
///
/// If you use a temporary directory, you should not rely on the existence of that temporary
/// directory after the app is exited. It is recommended that you remove any temporary directories
/// that are created after they're no longer needed. The caches directory may be a more appropriate
/// directory to use depending on your use case. Any files created in the caches directory may be
/// deleted by the system when the app is not running. Files placed in the documents directory will
/// be persisted and included in iCloud backups.
///
/// * [File System Programming Guide](https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileSystemOverview/FileSystemOverview.html)
/// // swiftlint:enable line_length
class FileSystem {
    enum Failure: Error {
        case fatalError(errorDescription: String)
    }
    /// Documents directory for files which are persisted and are backed up to iCloud.
    let documentsURL: URL
    /// Caches directory for files which can be recreated and can be cleared when app is not running.
    let cachesURL: URL

    static let `default`: FileSystem = {
        FileSystem()
    }()

    init() {
        // Note: This API supports many values for directories. The ones used here will always be available to an app.
        guard let documentsURL = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {
            fatalError("Failed to get URL for documents directory.")
        }
        guard let cachesURL = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) else {
            fatalError("Failed to get URL for caches directory.")
        }
        self.documentsURL = documentsURL
        self.cachesURL = cachesURL
    }

    /// Checks if a file exists
    /// - Parameter fileURL: URL of the file
    /// - Returns: exists
    func fileExists(atURL fileURL: URL) -> Bool {
        FileManager.default.fileExists(atPath: fileURL.path)
    }

    /// Checks if a directory exists
    /// - Parameter directoryURL: URL of the directory
    /// - Returns: exists
    func directoryExists(atURL directoryURL: URL) -> Bool {
        var isDir: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: directoryURL.path, isDirectory: &isDir) && isDir.boolValue
        return exists
    }

    /// Load contents from a file.
    /// - Parameter fileURL: URL of file to load
    /// - Returns: Data from file if it could be loaded
    func contents(atURL fileURL: URL) -> Data? {
        FileManager.default.contents(atPath: fileURL.path)
    }

    /// Creates URL for a temporary directory but does not create the directory.
    /// - Parameter baseURL: URL to use as the base which defaults to Caches Directory
    /// - Returns: URL for a temporary directory
    func createTemporaryDirectoryURL(baseURL: URL = FileSystem.default.cachesURL) -> URL {
        baseURL.appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

    /// Creates unique file URL in the Caches directory.
    ///
    /// The system may delete the Caches directory on rare occasions when the system is very low on disk space. This will never occur while an app is running.
    ///
    /// - Parameter baseURL: URL to use as the base which defaults to Caches Directory
    /// - Parameter filename: Filename which defaults to a UUID generated value by default
    /// - Returns: File URL
    func createTemporaryFileURL(baseURL: URL = FileSystem.default.cachesURL, filename: String = "\(UUID().uuidString).tmp") -> URL {
        baseURL.appendingPathComponent(filename)
    }

    /// Creates a file in the Caches directory which will not be deleted while the app is running.
    ///
    /// - Parameter data: Data to write to file
    /// - Parameter baseURL: URL to use as the base which defaults to Caches Directory
    /// - Throws: Error if write fails
    /// - Returns: File URL
    func createTemporaryFile(data: Data, baseURL: URL = FileSystem.default.cachesURL) throws -> URL {
        let temporaryFileURL = createTemporaryFileURL(baseURL: baseURL)
        try data.write(to: temporaryFileURL, options: .atomicWrite)

        return temporaryFileURL
    }

    /// Remove file if it exists
    /// - Parameter fileURL: URL of the file
    @discardableResult
    func removeFileIfExists(fileURL: URL) -> Bool {
        let success: Bool
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(at: fileURL)
                success = true
            } catch {
                success = false
            }
        } else {
            success = true
        }
        return success
    }

    /// Remove directory if it exists
    /// - Parameter directoryURL: URL of the directory
    func removeDirectoryIfExists(directoryURL: URL) {
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: directoryURL.path, isDirectory: &isDir) && isDir.boolValue {
            try? FileManager.default.removeItem(at: directoryURL)
        }
    }

    /// Create directory
    /// - Parameter directoryURL: URL of new directory
    func createDirectory(at directoryURL: URL) throws {
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    /// Create file
    /// - Parameters:
    ///   - baseURL: URL of the base directory
    ///   - filename: name of the file
    ///   - data: data
    /// - Returns: URL of the new file
    func createFile(baseURL: URL = FileSystem.default.cachesURL, filename: String, data: Data) throws -> URL {
        let fileURL = baseURL.appendingPathComponent(filename)
        try data.write(to: fileURL)
        return fileURL
    }

    /// Get list of contents in a directory matching a filter
    /// - Parameters:
    ///   - directoryURL: URL of direcetory
    ///   - matching: filter to limit matches
    /// - Returns: matched contents
    func directoryContents(directoryURL: URL, matching: @escaping (String) -> Bool) throws -> [URL] {
        let fileURLs = try FileManager.default.contentsOfDirectory(atPath: directoryURL.path)
            .filter(matching)
            .map {
                directoryURL.appendingPathComponent($0, isDirectory: false)
            }

        return fileURLs
    }

    /// Returns the size in bytes of a file.
    /// - Parameter fileURL: URL of the file
    /// - Returns: size of file in bytes
    func getFileSize(fileURL: URL) -> UInt64 {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
              let size = attributes[.size] as? UInt64 else {
            Fatal.require("File size should always be accessible")
        }
        return size
    }

    func moveFile(from sourceFileURL: URL, to destinationURL: URL) throws {
        guard FileManager.default.fileExists(atPath: destinationURL.path) else {
            throw Failure.fatalError(errorDescription: "File already exists at destination: \(destinationURL.path)")
        }
        try FileManager.default.moveItem(atPath: sourceFileURL.path, toPath: destinationURL.path)
    }

    /// Creates a partial file from a source file.
    /// - Parameters:
    ///   - fileURL: URL of the source file
    ///   - offset: position to start reading
    ///   - length: length of the part
    ///   - completionHandler: completion handler
    func createPartialFile(fileURL: URL, offset: Int, length: Int, completionHandler: @escaping (Result<URL, Error>) -> Void) {
        // 4.5 MB (1 MB per part)
        // 1024 1024 1024 1024 512

        // Move work off current context
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            // seek to the offset, read bytes and write data to a file
            do {
                let fileHandle = try FileHandle(forReadingFrom: fileURL)
                defer {
                    if #available(iOS 13.0, *) {
                        try? fileHandle.close()
                    } else {
                        fileHandle.closeFile()
                    }
                }
                if #available(iOS 13.0, *) {
                    try fileHandle.seek(toOffset: UInt64(offset))
                } else {
                    fileHandle.seek(toFileOffset: UInt64(offset))
                }
                let data = fileHandle.readData(ofLength: length)
                let fileURL = try self.createTemporaryFile(data: data)
                completionHandler(.success(fileURL))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }

}
