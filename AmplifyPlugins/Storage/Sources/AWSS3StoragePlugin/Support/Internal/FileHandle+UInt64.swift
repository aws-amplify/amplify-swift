//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension FileHandle {
    /// Reads data synchronously up to the specified number of bytes.
    /// - Parameter bytes: The number of bytes to read from the file handle.
    /// - Parameter bytesReadLimit: The maximum number of bytes that can be read at a time. Defaults to `Int.max`.
    /// - Returns: The data available through the receiver up to a maximum of length bytes, or the maximum size that can be represented by a Data object.
    /// - Throws: An error if attempts to determine the file-handle type fail or if attempts to read from the file or channel fail.
    func read(bytes: UInt64, bytesReadLimit: Int = Int.max) throws -> Data {
        // Read as much as it's possible considering the `bytesReadLimit` maximum
        let bytesRead = bytes <= bytesReadLimit ? Int(bytes) : bytesReadLimit
        guard var data = try readData(upToCount: bytesRead) else {
            // There is no more data to read from the file
            return Data()
        }

        // If there's remaining bytes to read, do it and append to the current data
        let remainingBytes = bytes - UInt64(bytesRead)
        if remainingBytes > 0 {
            try data.append(read(
                bytes: remainingBytes,
                bytesReadLimit: bytesReadLimit
            ))
        }

        return data
    }

    private func readData(upToCount length: Int) throws -> Data? {
        if #available(iOS 13.4, macOS 10.15.4, tvOS 13.4, *) {
            return try read(upToCount: length)
        } else {
            return readData(ofLength: length)
        }
    }
}
