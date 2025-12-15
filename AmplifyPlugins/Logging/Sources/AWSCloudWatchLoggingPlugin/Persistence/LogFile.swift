//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Represents an individual log file on disk used as part of a
/// LogRotation
final class LogFile {
    let fileURL: URL
    let sizeLimitInBytes: UInt64

    private let handle: FileHandle
    private var count: UInt64

    /// Creates a new file with the given URL and sets its attributes accordingly.
    init(forWritingTo fileURL: URL, sizeLimitInBytes: UInt64) throws {
        self.fileURL = fileURL
        self.sizeLimitInBytes = sizeLimitInBytes
        self.handle = try FileHandle(forWritingTo: fileURL)
        self.count = 0
    }

    /// Opens a file for updating with the given URL and sets its attributes accordingly.
    init(forAppending fileURL: URL, sizeLimitInBytes: UInt64) throws {
        self.fileURL = fileURL
        self.sizeLimitInBytes = sizeLimitInBytes
        self.handle = try FileHandle(forUpdating: fileURL)
        if #available(macOS 12.0, iOS 13.4, watchOS 6.2, tvOS 13.4, *) {
            self.count = try self.handle.offset()
        } else {
            self.count = handle.offsetInFile
        }
    }

    deinit {
        try? self.handle.close()
    }

    /// Returns the number of bytes available in the underlying file.
    var available: UInt64 {
        if sizeLimitInBytes > count {
            return sizeLimitInBytes - count
        } else {
            return 0
        }
    }

    /// Attempts to close the underlying log file.
    func close() throws {
        try handle.close()
    }

    /// Atempts to flush the receivers contents to disk.
    func synchronize() throws {
        try handle.synchronize()
    }

    /// - Returns: true if writing to the underlying log file will keep its size below the limit.
    func hasSpace(for data: Data) -> Bool {
        return UInt64(data.count) <= available
    }

    /// Writes the given **single line of text** represented as a
    /// Data  to the underlying log file.
    func write(data: Data) throws {
        if #available(macOS 12.0, iOS 13.4, watchOS 6.2, tvOS 13.4, *) {
            try self.handle.write(contentsOf: data)
        } else {
            handle.write(data)
        }
        try handle.synchronize()
        count = count + UInt64(data.count) // swiftlint:disable:this shorthand_operator
    }

}
