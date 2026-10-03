//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import Foundation

/// The identifier a session is saved under.
///
/// Two `AmplifyCognitoClient` instances built with the same `SessionID` are two handles onto
/// the same session. The app owns uniqueness: reusing an ID is not an error, it returns the
/// existing session.
///
/// A session is saved per pool configuration. Switching configuration under one **named** session ID (an app that
/// lets the user pick an organisation, say) keeps each configuration's record: switching back finds that
/// configuration's session as it was, unless it was signed out there. Only the changes the Auth plugin carries
/// forward (a pool added beside the same user pool or identity pool, or an identity pool changed or removed beside
/// the same user pool) carry the session into the new configuration. So two configurations that share a user pool
/// but differ in their identity pool are one carried session: a sign-out in either ends it in both. For runtime
/// switching between backends, use named sessions.
///
/// `.default` follows the Auth plugin's own rule instead, since it uses the plugin's saved login: see `default`.
///
/// Sessions exist only in `AmplifyCognitoClient` and the clients it hands credentials to. Amplify's
/// category plugins (Storage, Analytics, API and the rest) do not see them: they silently use the Auth
/// plugin's session in `Amplify.Auth`, whichever session ID you pick, `.default` included.
///
/// **Persisting one.** Save `stringValue` and rebuild the ID with `named(_:)`, which also turns `.default`'s
/// `"$default"` back into `.default`; or encode the ID itself: it is `Codable` as its `stringValue`, and
/// decoding accepts exactly what `named(_:)` accepts.
@_spi(AmplifyExperimental)
public struct SessionID: Hashable, Sendable {

    /// The value to persist in app storage in order to construct the same session later.
    public let stringValue: String

    private init(unchecked value: String) {
        self.stringValue = value
    }

    /// The single-account session, stable across launches.
    ///
    /// Its `stringValue` is `$default`. `$` is outside the charset `named(_:)` accepts for a name of the app's own
    /// (`named("$default")` is this ID, read back), so no app-chosen name can land on this session, not even
    /// `"default"`.
    ///
    /// **It uses the `AWSCognitoAuthPlugin`'s saved login.** Its session record is the plugin's own keychain item,
    /// holding the plugin's stored format, so an app moving from the plugin keeps its signed-in user, and an app
    /// rolled back to the plugin finds the newest login, signed out included. It is the only session that does, so
    /// one plugin record is never read by two session IDs. What the plugin's format has no room for — the label and,
    /// for a signed-out row, the last user — is kept beside it, bound to that user: a label never passes to a
    /// different user.
    ///
    /// **Side by side with the plugin is not supported.** The two share one saved login, but each keeps its tokens
    /// in memory and reads the keychain only at times of its own (the plugin at configuration), so a sign-in, a
    /// sign-out or, with refresh-token rotation, a refresh through one can leave the other holding tokens that no
    /// longer work until the app is relaunched. Use one or the other for the app's session.
    ///
    /// A user the plugin deletes (`deleteUser`) leaves the label and last user beside the record, so the picker can
    /// show that user's signed-out row until the client writes the session again: a sign-in through the client, or
    /// a client refresh of another user the plugin signed in. A sign-in through the plugin doesn't replace it.
    ///
    /// **A configuration change follows the plugin's rule**, and records the configuration as the plugin does, so a
    /// plugin build started next never copies an older login over a newer one. The login is copied, as it is, when a
    /// user pool is added beside the same identity pool, or an identity pool is added, changed or removed beside the
    /// same user pool, app client and region; a changed identity pool keeps the old identity ID, as the plugin does.
    /// Any other change of the pools deletes it; a deleted login of the same user pool is revoked, best effort, with
    /// the previous app client, and otherwise stays valid until it expires. A change of the app client alone keeps it,
    /// and its next refresh fails with `sessionExpired`. So `.default` keeps one backend's login at a time: for runtime
    /// switching between backends, use named sessions.
    public static let `default` = SessionID(unchecked: "$default")

    /// An app-chosen session ID.
    ///
    /// Must be 1 to 64 characters from `[A-Za-z0-9_-]`. The restriction is what keeps a `.` or `/`
    /// out of the storage key, so the key has no delimiter ambiguity. Comparison is
    /// case-sensitive: `"Work"` and `"work"` are different sessions, because merging them would
    /// silently cross credentials.
    ///
    /// The one exception is `"$default"`, `.default`'s `stringValue`, which returns `.default`, so a persisted
    /// `stringValue` always rebuilds its ID.
    ///
    /// - Throws: `AuthClientError.invalidSessionID` for an empty or overlong ID, or one naming the first
    ///   character outside the charset. The message never repeats the ID itself.
    public static func named(_ id: String) throws -> SessionID {
        if id == SessionID.default.stringValue {
            return .default
        }
        try validate(id)
        return SessionID(unchecked: id)
    }

    /// A library-minted session ID, for when the app has no stable identifier of its own.
    ///
    /// Each call mints a different ID, so persist the result (see "Persisting one" above): an ID not saved
    /// cannot find its session again in a later launch.
    public static func new() -> SessionID {
        SessionID(unchecked: UUID().uuidString.lowercased())
    }

    static let maximumLength = 64

    private static let sentinels: Set<String> = [
        SessionID.default.stringValue
    ]

    private static func isPermitted(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar {
        case "A" ... "Z", "a" ... "z", "0" ... "9", "_", "-":
            return true
        default:
            return false
        }
    }

    private static func validate(_ id: String) throws {
        guard !id.isEmpty else {
            throw AuthClientError.invalidSessionID(
                "A session ID cannot be empty.",
                "Pass a non-empty identifier, or use SessionID.new() to let the library mint one."
            )
        }
        guard id.unicodeScalars.count <= maximumLength else {
            throw AuthClientError.invalidSessionID(
                "A session ID can be at most \(maximumLength) characters; this one has \(id.unicodeScalars.count).",
                "Use a shorter identifier, or hash a long one before passing it."
            )
        }
        if let offender = id.unicodeScalars.first(where: { !isPermitted($0) }) {
            throw AuthClientError.invalidSessionID(
                "A session ID may only contain letters, digits, '_' and '-'; found \"\(offender)\".",
                "Remove or replace the character. The restriction keeps session IDs safe to use in storage keys."
            )
        }
    }

    /// Reconstructs a session ID read back from storage, accepting the library's own sentinels.
    /// Returns `nil` for anything `named(_:)` would reject, so a malformed record is skipped rather
    /// than crashing a listing.
    init?(storageComponent value: String) {
        if Self.sentinels.contains(value) {
            self.init(unchecked: value)
            return
        }
        guard (try? Self.validate(value)) != nil else {
            return nil
        }
        self.init(unchecked: value)
    }
}

extension SessionID: Codable {

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        guard let id = SessionID(storageComponent: value) else {
            // The rejected value is not repeated: it may be an identifier the app would not log.
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "The value is not a valid session ID."
            )
        }
        self = id
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stringValue)
    }
}

extension SessionID: CustomStringConvertible {
    public var description: String { stringValue }
}
