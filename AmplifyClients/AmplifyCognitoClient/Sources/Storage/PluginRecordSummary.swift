//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The view of the Auth plugin's stored record, `.default`'s session record, read without depending on the
/// plugin's types and without decoding its credentials: what `.default`'s reads and the picker take from it.
///
/// The plugin stores `AmplifyCredentials` with a plain `JSONEncoder` and synthesized `Codable`, and
/// existing users' sign-ins depend on that format, so it is frozen. An enum with associated values
/// encodes as an object with exactly one key, the case name, whose value holds the labelled
/// associated values:
///
/// ```json
/// {"userPoolOnly":{"signedInData":{"username":"…","userId":"…",…}}}
/// {"userPoolAndIdentityPool":{"signedInData":{"username":"…",…},"identityID":"…","credentials":{…}}}
/// {"identityPoolOnly":{"identityID":"…","credentials":{…}}}
/// {"identityPoolWithFederation":{"federatedToken":{…},"identityID":"…","credentials":{…}}}
/// {"noCredentials":{}}
/// ```
///
/// Only the case key, `signedInData.username`, `signedInData.userId` and `identityID` are read.
struct PluginRecordSummary: Equatable, Sendable {

    let kind: SessionKind
    let username: String?

    /// The user pool `sub`, for the signed-in kinds. Not listed; it tells two users apart.
    var userId: String?

    /// The identity pool identity, when the record has one. Not listed; it tells two guests apart.
    var identityId: String?

    /// Whether the record had a shape this build recognises. When it did not, `kind` is the
    /// conservative default below.
    let isRecognised: Bool

    /// The kind reported for a plugin record whose shape is not recognised.
    ///
    /// Not `.signedOut`: a plugin record is present, so hiding the row could show
    /// sign-in to a signed-in user — the outcome the listing exists to prevent. Not `.guest` or
    /// `.federated`: apps branch on those to render a guest row or skip sign-in, and nothing says the
    /// record is either. `.userPoolOnly` is the smallest signed-in claim: a user, with nothing asserted
    /// about identity-pool credentials. Using the session then confirms or corrects it.
    static let unrecognisedKind = SessionKind.userPoolOnly

    /// The signed-out record, `{"noCredentials":{}}`: what `.default` writes on sign-out. The bytes equal
    /// `JSONEncoder().encode(AmplifyCredentials.noCredentials)`, which every plugin release reads as signed out.
    static let signedOutPayload = Data(#"{"noCredentials":{}}"#.utf8)

    /// Whether `data` is a signed-out record, `{"noCredentials":{}}`: present, but holding no session.
    static func isSignedOut(_ data: Data) -> Bool {
        let summary = peek(data)
        return summary.isRecognised && summary.kind == .signedOut
    }

    static func peek(_ data: Data) -> PluginRecordSummary {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              object.count == 1,
              let entry = object.first,
              let kind = kind(forCaseName: entry.key) else {
            return PluginRecordSummary(kind: unrecognisedKind, username: nil, isRecognised: false)
        }
        let body = entry.value as? [String: Any]
        let signedInData = body?["signedInData"] as? [String: Any]
        let hasUser = kind == .userPoolOnly || kind == .userPoolAndIdentityPool
        return PluginRecordSummary(
            kind: kind,
            username: hasUser ? signedInData?["username"] as? String : nil,
            userId: hasUser ? signedInData?["userId"] as? String : nil,
            identityId: body?["identityID"] as? String,
            isRecognised: true
        )
    }

    /// The plugin's `AmplifyCredentials` case names. Frozen: they are the plugin's stored format.
    private static func kind(forCaseName caseName: String) -> SessionKind? {
        switch caseName {
        case "userPoolOnly": return .userPoolOnly
        case "userPoolAndIdentityPool": return .userPoolAndIdentityPool
        case "identityPoolOnly": return .guest
        case "identityPoolWithFederation": return .federated
        case "noCredentials": return SessionKind.signedOut
        default: return nil
        }
    }
}
