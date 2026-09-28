//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Recognises the keychain accounts that hold the standalone clients' session records.
///
/// Those records share a keychain service with `AWSCognitoAuthPlugin`, as siblings of its
/// `amplify.<poolNamespace>.session` record, under accounts of the form
/// `amplify.<schemaVersion>.<poolNamespace>.<sessionId>.<kind>`. Any code that clears or moves a shared
/// service in bulk must leave them alone, because they belong to sessions that code does not own.
///
/// Defined here, rather than in a client, because this module is the one both sides depend on: the
/// plugins reach it through `AWSPluginsCore`, and the clients depend on it directly, so neither has to
/// import the other.
package enum SessionRecordAccount {

    /// Whether `account` belongs to a client session record of **any** schema version, whatever its kind:
    /// `amplify.`, then one or more ASCII digits, then `.`.
    ///
    /// Every schema version is recognised, not only today's `1`, because a released plugin must spare
    /// records written by clients newer than itself.
    ///
    /// The plugin's own accounts never match: they are `authConfiguration` or begin with
    /// `amplify.<poolId>`, and a Cognito pool ID begins with its region (`us-east-1_…`,
    /// `us-east-1:…`), so it is never all digits.
    package static func isClientSessionRecord(_ account: String) -> Bool {
        // Byte-wise, so only ASCII digits count and no Unicode normalisation is involved.
        let prefix = "amplify.".utf8
        let bytes = account.utf8
        guard bytes.starts(with: prefix) else {
            return false
        }
        var digitCount = 0
        for byte in bytes.dropFirst(prefix.count) {
            if byte == UInt8(ascii: ".") {
                return digitCount > 0
            }
            guard (UInt8(ascii: "0") ... UInt8(ascii: "9")).contains(byte) else {
                return false
            }
            digitCount += 1
        }
        return false
    }
}
