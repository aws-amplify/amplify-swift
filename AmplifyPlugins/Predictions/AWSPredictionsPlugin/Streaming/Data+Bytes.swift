//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Data {
    /// Error thrown when preconditions aren't met when calling `readByte()` or `readBytes(count:)`
    enum ReadByteError: Error {
        case malformed
    }

    /// Retrieves and removes byte of `Data`. Functionally equivalent to `popFirst()`.
    ///
    ///   `Data` self-slices, meaning `Data.SubSequence == Data` [[reference](https://developer.apple.com/documentation/foundation/data/subsequence)]
    ///
    ///   This allows use to conduct mutating operations like `removeFirst(n)` without
    ///   incurring O(n) time complexity costs.
    ///
    /// - Note: This method throws `ReadByteError.malformed` if the `Data` instance is empty.
    /// - Complexity: O(1)
    /// - Returns: First byte (`UInt8`) in `self` (`Data`)
    @discardableResult
    mutating func readByte() throws -> UInt8 {
        guard let first = first else { throw ReadByteError.malformed }
        self.removeFirst()
        return first
    }


    /// Retrieves and removes `n` bytes of `Data`, where `n` = `count` argument
    ///
    ///   `Data` self-slices, meaning `Data.SubSequence == Data` [[reference](https://developer.apple.com/documentation/foundation/data/subsequence)]
    ///
    ///   This allows use to conduct mutating operations like `removeFirst(n)` without
    ///   incurring O(n) time complexity costs.
    ///
    /// - Note: This method throws `ReadByteError.malformed` if the `Data` instance doesn't contain `count` bytes..
    /// - Complexity: O(n) where `n` = `count` argument.
    /// - Returns: First `n` bytes  where `n` = `count` argument.
    @discardableResult
    mutating func readBytes(count: Int) throws -> Data {
        guard self.count >= count else { throw ReadByteError.malformed }
        defer { removeFirst(count) }
        return prefix(count)
    }
}
