//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Represents an individual log file on disk used as part of a
/// [LogRotation](x-source-tag://LogRotation).
///
/// - See: [LogRotation](x-source-tag://LogRotation)
///
/// - Tag: LogFile
final class LogFile {
    
    /// Error types owned by the LogFile class.
    ///
    /// - Tag: LogFileIOError
    enum IOError: Error {
        case spaceExceeded(data: Data, sizeLimitInBytes: UInt64)
    }
    
    let fileURL: URL
    let sizeLimitInBytes: UInt64
    
    private let handle: FileHandle
    private var count: UInt64
    
    /// Creates a new file with the given URL and sets its attributes accordingly.
    ///
    /// - Tag: LogFile.initForWritingTo
    init(forWritingTo fileURL: URL, sizeLimitInBytes: UInt64) throws {
        self.fileURL = fileURL
        self.sizeLimitInBytes = sizeLimitInBytes
        self.handle = try FileHandle(forWritingTo: fileURL)
        self.count = 0
    }

    /// Opens a file for updating with the given URL and sets its attributes accordingly.
    ///
    /// - Tag: LogFile.initForAppending
    init(forAppending fileURL: URL, sizeLimitInBytes: UInt64) throws {
        self.fileURL = fileURL
        self.sizeLimitInBytes = sizeLimitInBytes
        self.handle = try FileHandle(forUpdating: fileURL)
        if #available(macOS 10.15.4, iOS 13.4, watchOS 6.2, tvOS 13.4, *) {
            self.count = try self.handle.offset()
        } else {
            self.count = self.handle.offsetInFile
        }
    }
    
    deinit {
        try? self.handle.close()
    }
    
    /// Returns the number of bytes available in the underlying file.
    ///
    /// - Tag: LogFile.close
    var available: UInt64 {
        return sizeLimitInBytes - count
    }
    
    /// Attempts to close the underlying log file.
    ///
    /// - Tag: LogFile.close
    func close() throws {
        try self.handle.close()
    }
    
    /// Atempts to flush the receivers contents to disk.
    ///
    /// - Tag: LogFile.synchronize
    func synchronize() throws {
        try self.handle.synchronize()
    }
    
    /// - Returns: true if writing to the underlying log file will keep its size below the limit.
    ///
    /// - Tag: LogFile.hasSpace
    func hasSpace(for data: Data) -> Bool {
        return UInt64(data.count) <= self.available
    }
    
    /// Writes the given **single line of text** represented as a
    /// [Data](x-source-tag://Data) to the underlying log file.
    ///
    /// Please note that no line escaping will be done as part of writing to
    /// the underlying log file.
    ///
    /// - Tag: LogFile.write
    func write(data: Data) throws {
        if !hasSpace(for: data) {
            throw IOError.spaceExceeded(data: data, sizeLimitInBytes: sizeLimitInBytes)
        }
        
        if #available(macOS 10.15.4, iOS 13.4, watchOS 6.2, tvOS 13.4, *) {
            try self.handle.write(contentsOf: data)
        } else {
            self.handle.write(data)
        }
        try self.handle.synchronize()
        count = count + UInt64(data.count)
    }
    
}
