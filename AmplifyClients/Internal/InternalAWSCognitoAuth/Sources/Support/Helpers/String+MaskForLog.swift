//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// Engine-side copies of the plugin's `String.masked(...)` / `redacted()` helpers
// (`AWSCognitoAuthPlugin/Support/Helpers/String+Mask.swift`).
//
// The plugin's versions are `public` and stay where they are, because they are part of the
// plugin's public API. These are `package` and carry different names: the plugin imports this
// module, so identically named extensions would make every plugin call site ambiguous.
// Keep the bodies identical to the plugin's so log output does not change.

package extension String {

    /// Returns a masked version of the receiver. Same behaviour as the plugin's `masked(...)`.
    ///
    /// - Parameters:
    ///   - character: The character to obscure the interior of the string
    ///   - retainingCount: Number of characters to retain at both the beginning and end
    ///   of the string
    ///   - interiorCount: Number of masked characters in the interior of the string.
    ///   Defaults to actual size of string
    /// - Returns: A masked version of the string
    func maskedForLog(
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

    /// Same behaviour as the plugin's `redacted()`.
    func redactedForLog() -> Self {
        "<REDACTED>"
    }
}

package extension String? {
    /// Same behaviour as the plugin's `String?.masked(...)`.
    func maskedForLog(
        using character: Character = "*",
        interiorCount: Int = .max,
        retainingCount: Int = 2
    ) -> String {
        switch self {
        case .none:
            return "(nil)"
        case .some(let value):
            return value.maskedForLog(
                using: character,
                interiorCount: interiorCount,
                retainingCount: retainingCount
            )
        }
    }

    /// Same behaviour as the plugin's `String?.redacted()`.
    func redactedForLog() -> String {
        switch self {
        case .none:
            return "(nil)"
        case .some(let value):
            return value.redactedForLog()
        }
    }

}
