//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A sign-in stopped on a challenge, saved so it survives the app being closed (design §4.11 and §6).
///
/// Stored under `amplify.1.<poolNamespace>.<sessionId>.challenge` (`SessionRecordKey.Kind.challenge`), next to the
/// session record, with the same keychain service, access group and attributes: device-only
/// (`…AfterFirstUnlockThisDeviceOnly`) and never synchronizable. It exists exactly while the session's engine holds a
/// pending sign-in it can resume: written when a sign-in step stops on a challenge, kept across a wrong answer, and
/// deleted when the sign-in completes, fails for good, is superseded or cancelled, and on sign-out, purge and user
/// deletion.
///
/// **What it holds**: the Cognito challenge session string and what `RespondToAuthChallenge` (or the TOTP setup's
/// `VerifySoftwareToken`) needs besides the answer, and the step the user was on. **Never** a password, the
/// `signIn` call's client metadata, SRP state, tokens or hosted-UI state.
///
/// **Its lifetime is Cognito's**, which the client cannot see: an app client's `AuthSessionValidity`, 3 to 15
/// minutes. The library does not predict it (design §4.11): a record is resumed, and an expired one fails `confirmSignIn`
/// with `challengeExpired`. Only a record older than `ceiling`, Cognito's longest validity, is certainly dead, and is
/// deleted instead of resumed.
///
/// The stored format is this type's own JSON (sorted keys), not the engine's types' synthesized `Codable`, so the
/// engine's types can change without changing what is stored. Changing a stored key or kind spelling changes the
/// format: `ChallengeRecordFormatTests` pins it.
struct ChallengeRecord: Equatable, Sendable {

    /// The newest schema this build reads, and the one it writes.
    ///
    /// **Adding a `Step.Kind`, a `CodeDelivery.medium` or an `authFlow` spelling needs a bump.** An older build decodes
    /// an unknown kind as `.corrupt` and deletes the record on restore, where it would leave a newer schema's record
    /// for its writer. A new optional key does not need one: readers ignore keys they do not know.
    static let currentSchemaVersion = 1

    /// Cognito's longest challenge session: `AuthSessionValidity` is 3 to 15 minutes. A record older than this cannot
    /// be answered whatever the app client's setting.
    static let ceiling: TimeInterval = 15 * 60

    /// When the Cognito session string was received, at millisecond precision (the stored resolution). A rewrite
    /// that keeps the same session string keeps this (`SessionRecordStore.writeChallenge`).
    var createdAt: Date

    var state: State

    init(createdAt: Date, state: State) {
        self.createdAt = Self.roundedToMilliseconds(createdAt)
        self.state = state
    }

    /// What the sign-in is waiting on.
    enum State: Equatable, Sendable {
        /// A `RespondToAuthChallenge` challenge: an MFA or OTP code, a new password, a custom challenge, an MFA
        /// or first-factor selection, a password.
        case challenge(Challenge)
        /// A TOTP setup during sign-in (`MFA_SETUP` for `SOFTWARE_TOKEN_MFA`): the shared secret the user is
        /// adding to their authenticator, and the setup's session.
        case totpSetup(TOTPSetup)

        /// The Cognito session string the next answer is sent with.
        var session: String? {
            switch self {
            case .challenge(let challenge): return challenge.session
            case .totpSetup(let setup): return setup.session
            }
        }
    }

    /// A `RespondToAuthChallenge` challenge, as the engine's `RespondToAuthChallenge` holds it, and its step.
    struct Challenge: Codable, Equatable, Sendable {
        /// Cognito's `ChallengeName`, as Cognito spells it (`SMS_MFA`, `SELECT_CHALLENGE`, …).
        var challengeName: String
        /// Cognito's `AvailableChallenges`, as Cognito spells them.
        var availableChallenges: [String]
        /// The user pool username the challenge is for (`USERNAME` in the answer).
        var username: String
        /// The username the app signed in with, if it differs (an alias).
        var inputUsername: String?
        var session: String?
        /// Cognito's `ChallengeParameters`.
        var parameters: [String: String]?
        var signInMethod: SignInMethod
        /// The step the user was on: not always derivable from the challenge (a first-factor selection of
        /// `PASSWORD` waits on `confirmSignInWithPassword` under the selection's challenge).
        var step: Step
    }

    /// A TOTP setup during sign-in.
    struct TOTPSetup: Codable, Equatable, Sendable {
        /// The TOTP shared secret `AssociateSoftwareToken` returned. The step shows it to the user again.
        var secretCode: String
        var session: String
        /// The user pool username the setup is for.
        var username: String
        /// The username the sign-in was started with, if the engine held one.
        var signInUsername: String?
        var signInMethod: SignInMethod
    }

    /// How the sign-in was started: the flow, and `USER_AUTH`'s preferred first factor.
    struct SignInMethod: Codable, Equatable, Sendable {
        /// `userSRP`, `custom`, `customWithSRP`, `customWithoutSRP`, `userPassword` or `userAuth`.
        var authFlow: String
        /// Cognito's spelling (`PASSWORD`, `EMAIL_OTP`, …), for `userAuth` only.
        var preferredFirstFactor: String?
    }

    /// The step a challenge waits on: its kind, and the payload the kind carries.
    struct Step: Codable, Equatable, Sendable {

        /// The step's case, spelled as `AuthClientSignInStep` spells it. Frozen: part of the stored format.
        enum Kind: String, Codable, Sendable, CaseIterable {
            case confirmSignInWithSMSMFACode
            case confirmSignInWithCustomChallenge
            case confirmSignInWithNewPassword
            case confirmSignInWithPassword
            case confirmSignInWithTOTPCode
            case continueSignInWithMFASelection
            case continueSignInWithEmailMFASetup
            case continueSignInWithMFASetupSelection
            case confirmSignInWithOTP
            case continueSignInWithFirstFactorSelection
        }

        var kind: Kind
        /// For the SMS MFA code and the OTP.
        var codeDelivery: CodeDelivery?
        /// For the SMS MFA code, the custom challenge and the new password.
        var additionalInfo: [String: String]?
        /// For the MFA selections: Cognito's spellings (`SMS_MFA`, `SOFTWARE_TOKEN_MFA`, `EMAIL_OTP`), sorted.
        var mfaTypes: [String]?
        /// For the first-factor selection: Cognito's spellings (`PASSWORD`, `WEB_AUTHN`, …), sorted.
        var factorTypes: [String]?

        init(
            kind: Kind,
            codeDelivery: CodeDelivery? = nil,
            additionalInfo: [String: String]? = nil,
            mfaTypes: [String]? = nil,
            factorTypes: [String]? = nil
        ) {
            self.kind = kind
            self.codeDelivery = codeDelivery
            self.additionalInfo = additionalInfo
            self.mfaTypes = mfaTypes
            self.factorTypes = factorTypes
        }
    }

    /// Where a code was sent.
    struct CodeDelivery: Codable, Equatable, Sendable {
        /// `email`, `phone`, `sms` or `unknown`.
        var medium: String
        /// The masked destination Cognito reported.
        var destination: String?
        /// The attribute the code verifies, in Cognito's spelling.
        var attributeKey: String?
    }

    /// Whether the record is more than `ceiling` away from `now`, so certainly dead. Either way: a `createdAt` more
    /// than `ceiling` after `now` means the clock moved back by more than any challenge lives, and the record's age
    /// cannot be known, so it is treated as dead too, rather than resumed for as long as the clock stays behind.
    func isPastCeiling(at now: Date) -> Bool {
        abs(now.timeIntervalSince(createdAt)) > Self.ceiling
    }

    private static func roundedToMilliseconds(_ date: Date) -> Date {
        Date(timeIntervalSince1970: TimeInterval(milliseconds(of: date)) / 1_000)
    }

    fileprivate static func milliseconds(of date: Date) -> Int64 {
        Int64((date.timeIntervalSince1970 * 1_000).rounded())
    }
}

// MARK: - Stored format

extension ChallengeRecord: Codable {

    /// The on-disk key names. Changing a raw value here changes the stored format. Exactly one of `challenge` and
    /// `totpSetup` is present.
    enum CodingKeys: String, CodingKey {
        case schemaVersion
        case createdAt
        case challenge
        case totpSetup
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let milliseconds = try container.decode(Int64.self, forKey: .createdAt)
        let challenge = try container.decodeIfPresent(Challenge.self, forKey: .challenge)
        let setup = try container.decodeIfPresent(TOTPSetup.self, forKey: .totpSetup)
        let state: State
        switch (challenge, setup) {
        case (let challenge?, nil):
            state = .challenge(challenge)
        case (nil, let setup?):
            state = .totpSetup(setup)
        default:
            throw DecodingError.dataCorruptedError(
                forKey: .challenge,
                in: container,
                debugDescription: "A challenge record holds exactly one of a challenge and a TOTP setup."
            )
        }
        self.init(createdAt: Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1_000), state: state)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Self.currentSchemaVersion, forKey: .schemaVersion)
        try container.encode(Self.milliseconds(of: createdAt), forKey: .createdAt)
        switch state {
        case .challenge(let challenge):
            try container.encode(challenge, forKey: .challenge)
        case .totpSetup(let setup):
            try container.encode(setup, forKey: .totpSetup)
        }
    }
}

extension ChallengeRecord {

    /// What a stored blob turned out to be.
    enum Decoded: Equatable, Sendable {
        case record(ChallengeRecord)
        /// A well-formed record written by a newer schema: not resumed, and left for its writer.
        case unsupportedSchema(version: Int)
        /// Bytes that are not a challenge record of any schema version.
        case corrupt
    }

    private struct VersionProbe: Decodable {
        let schemaVersion: Int
    }

    static func decode(_ data: Data) -> Decoded {
        let decoder = JSONDecoder()
        guard let probe = try? decoder.decode(VersionProbe.self, from: data), probe.schemaVersion >= 1 else {
            return .corrupt
        }
        guard probe.schemaVersion <= currentSchemaVersion else {
            return .unsupportedSchema(version: probe.schemaVersion)
        }
        guard let record = try? decoder.decode(ChallengeRecord.self, from: data) else {
            return .corrupt
        }
        return .record(record)
    }

    func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(self)
    }
}

// MARK: - Redaction

// The record holds a live Cognito session string, the username and, for a TOTP setup, the shared secret: none of
// them reaches a log through interpolation, `print`, `debugPrint`, `dump` or a debugger. Challenge parameters show
// their keys only.

extension ChallengeRecord: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {

    var description: String {
        "ChallengeRecord(createdAt: \(createdAt), state: \(state))"
    }

    var debugDescription: String {
        description
    }

    var customMirror: Mirror {
        Mirror(self, children: ["createdAt": createdAt, "state": state], displayStyle: .struct)
    }
}

extension ChallengeRecord.State: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {

    var description: String {
        switch self {
        case .challenge(let challenge): return "challenge(\(challenge))"
        case .totpSetup(let setup): return "totpSetup(\(setup))"
        }
    }

    var debugDescription: String {
        description
    }

    var customMirror: Mirror {
        switch self {
        case .challenge(let challenge): return Mirror(self, children: ["challenge": challenge], displayStyle: .enum)
        case .totpSetup(let setup): return Mirror(self, children: ["totpSetup": setup], displayStyle: .enum)
        }
    }
}

extension ChallengeRecord {
    static let redacted = "<redacted>"
}

extension ChallengeRecord.Challenge: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {

    private var parameterKeys: [String] {
        (parameters ?? [:]).keys.sorted()
    }

    var description: String {
        "Challenge(challengeName: \(challengeName), availableChallenges: \(availableChallenges), username: "
            + "\(ChallengeRecord.redacted), session: \(ChallengeRecord.redacted), parameterKeys: \(parameterKeys), "
            + "signInMethod: \(signInMethod.authFlow), step: \(step.kind.rawValue))"
    }

    var debugDescription: String {
        description
    }

    var customMirror: Mirror {
        Mirror(self, children: [
            "challengeName": challengeName,
            "availableChallenges": availableChallenges,
            "username": ChallengeRecord.redacted,
            "session": ChallengeRecord.redacted,
            "parameterKeys": parameterKeys,
            "signInMethod": signInMethod.authFlow,
            "step": step.kind.rawValue
        ], displayStyle: .struct)
    }
}

extension ChallengeRecord.TOTPSetup: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {

    var description: String {
        "TOTPSetup(secretCode: \(ChallengeRecord.redacted), session: \(ChallengeRecord.redacted), username: "
            + "\(ChallengeRecord.redacted), signInMethod: \(signInMethod.authFlow))"
    }

    var debugDescription: String {
        description
    }

    var customMirror: Mirror {
        Mirror(self, children: [
            "secretCode": ChallengeRecord.redacted,
            "session": ChallengeRecord.redacted,
            "username": ChallengeRecord.redacted,
            "signInMethod": signInMethod.authFlow
        ], displayStyle: .struct)
    }
}
