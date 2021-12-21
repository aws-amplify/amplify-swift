//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public extension String {

    /// Returns a masked version of the receiver.
    ///
    /// - Parameters:
    ///   - character: The character to obscure the interior of the string
    ///   - retainingCount: Number of characters to retain at both the beginning and end
    ///   of the string
    ///   - interiorCount: Number of masked characters in the interior of the string.
    ///   Defaults to actual size of string
    /// - Returns: A masked version of the string
    func masked(
        using character: Character = "*",
        interiorCount: Int = .max,
        retainingCount: Int = 2
    ) -> String {
        guard count >= retainingCount * 2 else {
            return String(repeating: character, count: count)
        }

        let interiorCharacterCount = count - (retainingCount * 2)
        let actualMaskSize = min(interiorCharacterCount, interiorCount)
        let mask = String(repeating: character, count: actualMaskSize)

        let prefix = prefix(retainingCount)
        let suffix = suffix(retainingCount)
        let maskedString = prefix + mask + suffix
        return String(maskedString)
    }

    func redacted() -> Self {
        "<REDACTED>"
    }
}

public extension Optional where Wrapped == String {
    func masked(
        using character: Character = "*",
        interiorCount: Int = .max,
        retainingCount: Int = 2
    ) -> String {
        switch self {
        case .none:
            return "(nil)"
        case .some(let value):
            return value.masked(
                using: character,
                interiorCount: interiorCount,
                retainingCount: retainingCount
            )
        }
    }

    func redacted() -> String {
        switch self {
        case .none:
            return "(nil)"
        case .some(let value):
            return value.redacted()
        }
    }

}
