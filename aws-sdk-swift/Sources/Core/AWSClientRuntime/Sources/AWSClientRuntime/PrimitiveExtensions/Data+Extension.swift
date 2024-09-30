//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Data {
    /// Returns an array of `Data` instances by splitting the receiver into equal sized chunks.
    /// The last instance may be less than the provided size since it will contain the last remaining chunk of data.
    ///
    /// - Parameter size: The maximum size, in bytes, of each data chunk
    /// - Returns: An array of `Data` instances
    func chunked(size: Int) -> [Data] {
        return stride(from: 0, to: count, by: size).map {
            self[$0 ..< Swift.min($0 + size, count)]
        }
    }

    /// Returns an array of bytes representing the data.
    /// - Returns: A byte array representation of the data.
    func bytes() -> [UInt8] {
        return [UInt8](self)
    }
}
