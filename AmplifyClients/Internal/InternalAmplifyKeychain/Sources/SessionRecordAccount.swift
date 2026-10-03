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

    /// The suffixes of the two items the Cognito client keeps for its default session beside the plugin's
    /// own record: the sidecar (label and last user) and the interrupted sign-in.
    private static let defaultSessionItemSuffixes = [".$default.meta", ".$default.challenge"]

    /// Whether `account` is one of the two items the Cognito client keeps for its **default** session,
    /// `amplify.<digits>.<pool namespace>.$default.meta` or `amplify.<digits>.<pool namespace>.$default.challenge`.
    ///
    /// The default session's login is the plugin's own record, so these two items belong to the plugin's
    /// session: the plugin's access-group migration moves them with its record, and its access-group
    /// transition wipe removes them. Every other client record, including a development build's leftover
    /// `$default.session`, still stays where the client put it.
    ///
    /// Every match is also a client session record (`isClientSessionRecord`).
    package static func isDefaultSessionItem(_ account: String) -> Bool {
        guard isClientSessionRecord(account) else {
            return false
        }
        // Byte-wise, as above. What follows `amplify.<digits>.` must be a non-empty pool namespace, then
        // one of the suffixes.
        let dot = UInt8(ascii: ".")
        let afterVersion = account.utf8.drop { $0 != dot }.dropFirst().drop { $0 != dot }.dropFirst()
        return defaultSessionItemSuffixes.contains { suffix in
            afterVersion.count > suffix.utf8.count && afterVersion.reversed().starts(with: suffix.utf8.reversed())
        }
    }
}
