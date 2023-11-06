//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Represents a directory that contains a set of log files that are part of a LogRotation.
final class LogRotation {
    
    enum LogRotationError: Error {
        /// Represents the scenario when a caller attempts to initialize a
        /// `LogRotation` with an invalid file size limit (minimum is 1KB).
        case invalidFileSizeLimitInBytes(Int)
    }
    
    static let minimumFileSizeLimitInBytes = 1024 /* 1KB */
    
    /// The name pattern of files managed by `LogRotation`.
    private static let filePattern = #"amplify[.]([0-9])[.]log"#

    let directory: URL
    let fileCountLimit: Int = 5
    let fileSizeLimitInBytes: UInt64
    
    private(set) var currentLogFile: LogFile {
        willSet {
            try? currentLogFile.synchronize()
            try? currentLogFile.close()
        }
    }

    init(directory: URL, fileSizeLimitInBytes: Int) throws {
        if (fileSizeLimitInBytes < LogRotation.minimumFileSizeLimitInBytes) {
            throw LogRotationError.invalidFileSizeLimitInBytes(fileSizeLimitInBytes)
        }
        
        self.directory = directory.absoluteURL
        self.fileSizeLimitInBytes = UInt64(fileSizeLimitInBytes)
        self.currentLogFile = try Self.selectNextLogFile(from: self.directory,
                                                         fileCountLimit: fileCountLimit,
                                                         fileSizeLimitInBytes: self.fileSizeLimitInBytes)
    }
    
    /// Selects the most-available log file.
    ///
    /// The criteria is roughly as follows:
    ///
    /// 1. If there is any file whose index falls in the range
    ///   (0..[fileCountLimit](x-source-tag://LogRotation.fileCountLimit)) that
    ///   has not been created, it is created and selected.
    /// 2. Any files containing less than half the limit are filtered, then the one with the oldest last modified date is selected.
    /// 3. If no files matching #1 are present, the file with the oldest last modified date is cleared and selected.
    func rotate() throws {
        self.currentLogFile = try Self.selectNextLogFile(from: self.directory,
                                                         fileCountLimit: self.fileCountLimit,
                                                         fileSizeLimitInBytes: self.fileSizeLimitInBytes)
    }
    
    func getAllLogs() throws -> [URL] {
        return try Self.listLogFiles(in: directory)
    }
    
    func reset() throws {
        let existingFiles = try Self.listLogFiles(in: directory)
        for file in existingFiles {
            try FileManager.default.removeItem(at: file)
        }
        self.currentLogFile = try Self.createLogFile(in: directory,
                                                     index: 0,
                                                     fileSizeLimitInBytes: fileSizeLimitInBytes)
    }
    
    private static func selectNextLogFile(from directory: URL,
                                          fileCountLimit: Int,
                                          fileSizeLimitInBytes: UInt64) throws -> LogFile {
        let existingFiles = try Self.listLogFiles(in: directory)
        if let index = try Self.nextUnallocatedIndex(from: existingFiles, fileCountLimit: fileCountLimit) {
            return try createLogFile(in: directory,
                                     index: index,
                                     fileSizeLimitInBytes: fileSizeLimitInBytes)
        }
        
        if let underutilized = try Self.oldestUnderutilizedFile(from: existingFiles,
                                                                sizeLimitInBytes: fileSizeLimitInBytes) {
            return try LogFile(forAppending: underutilized,
                               sizeLimitInBytes: fileSizeLimitInBytes)
        }

        if let oldestFileURL = existingFiles.last {
            return try LogFile(forWritingTo: oldestFileURL,
                               sizeLimitInBytes: fileSizeLimitInBytes)
        }
        
        return try createLogFile(in: directory,
                                 index: 0,
                                 fileSizeLimitInBytes: fileSizeLimitInBytes)
    }
    
    func ensureFileExists() throws {
        if !FileManager.default.fileExists(atPath: currentLogFile.fileURL.relativePath) {
            try rotate()
        }
    }

    /// - Returns: A UInt representing the best guess to which index to use
    ///            next when the number of log files is less that the limit
    ///            count.
    private static func nextUnallocatedIndex(from existingFiles: [URL], fileCountLimit: Int) throws -> Int? {
        if existingFiles.isEmpty {
            return nil
        }
        if existingFiles.count >= fileCountLimit {
            return nil
        }
        typealias FileIndexRef = (URL, Int)
        let references = try existingFiles.compactMap { try LogRotation.index(of: $0) }
                                          .filter { (0..<fileCountLimit).contains($0) }
                                          .sorted()
        guard let lastIndex = references.last else {
            return Int(existingFiles.count)
        }
        return (lastIndex + 1) % fileCountLimit
    }
    
    /// - Returns: The URL for the file with the oldest last modified date (assumes that the list of files are presorted by date with oldest last) that
    ///            also is taking up less than half of the size limit.
    private static func oldestUnderutilizedFile(from existingFiles: [URL], sizeLimitInBytes: UInt64) throws -> URL? {
        let fileManager: FileManager = FileManager.default
        let underutilizedFiles = try existingFiles.filter { url in
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            guard let size = attributes[.size] as? Int else { return false }
            return size < (sizeLimitInBytes / 2)
        }
        return underutilizedFiles.last
    }

    /// - Returns: The list of files within the given directory that match the
    /// file naming pattern ordered by last modified date descending
    /// (most-recently modified first).
    private static func listLogFiles(in directory: URL) throws -> [URL] {
        let fileManager: FileManager = FileManager.default
        let propertyKeys: [URLResourceKey] = [.contentModificationDateKey, .nameKey, .fileSizeKey]
        return try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys:propertyKeys)
            .filter { try index(of: $0) != nil }
            .sorted(by: { lhs, rhs in
                let lhsAttributes = try fileManager.attributesOfItem(atPath: lhs.path)
                guard let lhsDate = lhsAttributes[.modificationDate] as? Date else { return false }

                let rhsAttributes = try fileManager.attributesOfItem(atPath: rhs.path)
                guard let rhsDate = rhsAttributes[.modificationDate] as? Date else { return false }

                return lhsDate > rhsDate
            })
    }

    /// Returns the logical index of the file represented by the given URL
    /// **if its name matches** LogRotation.filePattern
    private static func index(of fileURL: URL) throws -> Int? {
        let fileName = fileURL.lastPathComponent
        let regex = try NSRegularExpression(pattern: filePattern, options: [.caseInsensitive])
        let matches = regex.matches(in: fileName, range: NSRange(location: 0, length: fileName.count))
        guard let match = matches.first else {
            return nil
        }
        // The whole file name pattern + the only capture group
        let expectedRangeCount = 2
        if match.numberOfRanges != expectedRangeCount {
            return nil
        }
        let captureGroupRange = match.range(at: 1)
        let indexString = (fileName as NSString).substring(with: captureGroupRange)
        return Int(indexString)
    }

    /// - Returns: An empty LogFile within the given
    /// directory using the given index whose name matches the
    /// amplify.<index>.log name pattern.
    private static func createLogFile(in directory: URL,
                                      index: Int,
                                      fileSizeLimitInBytes: UInt64) throws -> LogFile {
        let fileManager: FileManager = FileManager.default
        let fileURL = directory.appendingPathComponent("amplify.\(index).log")
        fileManager.createFile(atPath: fileURL.path,
                               contents: nil,
                               attributes: [FileAttributeKey : Any]())
        if #available(macOS 11.0, *) {
            let resourceValues: [URLResourceKey : Any] = [URLResourceKey.fileProtectionKey: URLFileProtection.complete, URLResourceKey.isExcludedFromBackupKey: true]
            try (fileURL as NSURL).setResourceValues(resourceValues)
        }  else {
            let resourceValues: [URLResourceKey : Any] = [URLResourceKey.isExcludedFromBackupKey: true]
            try (fileURL as NSURL).setResourceValues(resourceValues)
        }
        
        return try LogFile(forWritingTo: fileURL, sizeLimitInBytes: fileSizeLimitInBytes)
    }
}
