//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import CryptoKit
import Foundation

/// That a refresh proved a session's refresh token dead, saved with the session's record so that a new session core,
/// after every handle and provider of the session was released or after a relaunch, starts expired rather than
/// refreshing the dead token again (`SessionCore.savedExpiry(in:)`).
///
/// **It is bound to the dead token**, not to the record: `token` is a digest of the refresh token proved dead (or, for
/// credentials without one, such as a federated session's refused provider token, of the credentials' bytes). It
/// applies only while the record still holds that token, so a new login, a new federation, or a sign-out saved by any
/// writer ends it, whether or not that writer kept or cleared this marker: the Auth plugin, which never reads or writes
/// it, an app extension, or an earlier build, which drops the key it does not know.
///
/// Stored as `{"cause":"reused","token":"<64 hex digits>"}`: in a named session's envelope (`SessionRecordEnvelope`,
/// key `deadToken`), and in `.default`'s sidecar (`DefaultSessionMeta`, key `deadToken`), beside the plugin's record,
/// which has no room for it. An additive key in both, written only when set, so it needs no schema bump. A value this
/// build cannot read (a newer build's cause, say) is ignored, never taken for a corrupt record: the session then
/// refreshes as if nothing were saved.
struct DeadToken: Equatable, Sendable {

    /// What proved the token dead, which decides the error the session answers with.
    enum Cause: String, Sendable {
        /// Refused twice as reused, `RefreshTokenReuse.minimumGap` apart, with nobody saving a refresh
        /// (`SessionCore.refreshTokenAlreadyUsed(_:)`).
        case reused
        /// Refused as expired or revoked (`SessionCore.sessionExpired(_:)`), or a federated session's provider token
        /// refused by the identity pool (`SessionCore.providerTokenRefused(_:)`).
        case invalid
    }

    /// The SHA-256 digest, in lowercase hex, of the dead token (`digest(refreshToken:credentials:)`).
    let token: String
    let cause: Cause

    /// The digest that binds a marker to a token: of `refreshToken` when the credentials hold one, else of the
    /// credentials' bytes. Tagged, so the two never collide.
    static func digest(refreshToken: String?, credentials: Data) -> String {
        let input = refreshToken.map { Data("refreshToken:\($0)".utf8) } ?? Data("credentials:".utf8) + credentials
        return SHA256.hash(data: input).map { String(format: "%02x", $0) }.joined()
    }
}

extension DeadToken: Codable {

    /// The on-disk key names. Changing a raw value here changes the stored format.
    enum CodingKeys: String, CodingKey {
        case token
        case cause
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let causeValue = try container.decode(String.self, forKey: .cause)
        guard let cause = Cause(rawValue: causeValue) else {
            throw DecodingError.dataCorruptedError(
                forKey: .cause,
                in: container,
                debugDescription: "\"\(causeValue)\" is not a cause this build reads."
            )
        }
        try self.init(token: container.decode(String.self, forKey: .token), cause: cause)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(token, forKey: .token)
        try container.encode(cause.rawValue, forKey: .cause)
    }
}

extension KeyedDecodingContainer {

    /// The marker under `key`, or `nil` when there is none or it cannot be read: an unreadable marker is ignored, never
    /// taken for a corrupt record.
    func decodeDeadTokenIfReadable(forKey key: Key) -> DeadToken? {
        (try? decodeIfPresent(DeadToken.self, forKey: key)) ?? nil
    }
}
