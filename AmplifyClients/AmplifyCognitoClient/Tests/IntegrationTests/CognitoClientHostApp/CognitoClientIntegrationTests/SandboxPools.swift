//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Shared with CognitoClientUITests (the hosted-UI UI tests), which compiles this file and the five other
// shared sandbox helpers (IntegrationTestEnvironment, SandboxPools, SandboxSignUp, SandboxUserCleanup,
// CodeSink, TOTP) and nothing else from this folder. Keep it self-contained: it may use only those files,
// AmplifyCognitoClient, AWSCognitoIdentityProvider, Foundation, Security, CryptoKit and XCTest.

@_spi(AmplifyExperimental) import AmplifyCognitoClient
import AWSCognitoIdentityProvider
import Foundation

/// The multi-pool fixtures: one entry point per plugin-parity pool
/// for everything a parity test needs besides its assertions.
///
/// `SandboxPools.pool(.standard)` gives the pool's `AuthClientConfiguration` (for the client under
/// test) and a plain SDK client on the same public app client (for setup, raw checks and cleanup).
/// Every call is unauthenticated or authorized by a user's own tokens, so no AWS credentials are
/// needed. The build phase copies every role's plugin outputs file into the bundle.
enum SandboxPools {

    /// The pools whose users the helpers sign up and clean up with a raw password sign-in: every case but
    /// `hostedUI`, whose app client offers no password flow (on the sandbox, a second app client on
    /// `standard`).
    static let userPools: [SandboxPool] = SandboxPool.allCases.filter { $0 != .hostedUI }

    /// The fixtures of `pool`. Fails (never skips) when the pool's outputs file is missing.
    static func pool(_ pool: SandboxPool) throws -> SandboxPoolClient {
        try SandboxPoolClient(pool)
    }
}

extension SandboxPool {

    /// Whether the pool's username attribute is the email (U-ALIAS). There, the username a user signs
    /// in with is the email, and Cognito generates the user's real username, which is what the code sink
    /// is keyed by.
    var usesEmailAsUsername: Bool {
        self == .emailAlias
    }

    /// Whether the pool requires MFA at sign-in (U-REQ-*).
    var requiresMFA: Bool {
        [.mfaRequiredTOTPSMS, .mfaRequiredEmail, .mfaRequiredAll].contains(self)
    }

    /// Whether the pool tracks devices, always remembered (U-DEF and every pool created from its
    /// template: the MFA-required pools and U-ALIAS). U-PL and U-WA do not.
    var tracksDevices: Bool {
        ![.passwordless, .webAuthn].contains(self)
    }

    /// The features, by the names the tests require them by, that the outputs file shows the pool lacks:
    /// `email-mfa` and `sms-mfa` without `EMAIL` or `SMS` in `mfa_methods`. What the outputs do not
    /// describe (the first factors, WebAuthn) is taken as live, and a test that needs it fails at Cognito.
    func missingFeatures() throws -> [String] {
        let methods = try IntegrationTestEnvironment.outputsAuthSection(self)["mfa_methods"] as? [String] ?? []
        var missing: [String] = []
        if !methods.contains("EMAIL") {
            missing.append("email-mfa")
        }
        if !methods.contains("SMS") {
            missing.append("sms-mfa")
        }
        return missing
    }
}

/// One parity pool: the configuration the client under test loads, and a plain SDK client on the same
/// public app client.
struct SandboxPoolClient: Sendable {
    let pool: SandboxPool
    /// The pool's outputs, loaded exactly as an app loads them.
    let configuration: AuthClientConfiguration
    /// A plain SDK client for the pool's region. Its calls carry no AWS credentials.
    let client: CognitoIdentityProviderClient
    /// The public app client every call goes through.
    let clientId: String
    /// The features a test may need that the pool's outputs show it lacks (`SandboxPool.missingFeatures()`).
    let pending: [String]

    init(_ pool: SandboxPool) throws {
        let configuration = try IntegrationTestEnvironment.configuration(pool)
        guard let userPool = configuration.userPool else {
            throw HarnessError.malformedFixture("\(pool.outputsResource).json has no user pool.")
        }
        self.pool = pool
        self.configuration = configuration
        self.clientId = userPool.appClientId
        self.client = try CognitoIdentityProviderClient(
            config: CognitoIdentityProviderClient.CognitoIdentityProviderClientConfig(region: userPool.region)
        )
        self.pending = try pool.missingFeatures()
    }

    /// Fails (never skips) when the pool's outputs show it lacks `feature`, naming what the backend needs.
    func requireLive(_ feature: String) throws {
        guard !pending.contains(feature) else {
            throw HarnessError.malformedFixture("""
            \(pool.outputsResource).json shows no \(feature): the backend needs it enabled for this test.
            """)
        }
    }

    // MARK: - Raw sign-in

    /// `USER_PASSWORD_AUTH` with the user's current password. The answer may be a challenge.
    func passwordSignIn(_ user: TestUser) async throws -> InitiateAuthOutput {
        try await client.initiateAuth(input: InitiateAuthInput(
            authFlow: .userPasswordAuth,
            authParameters: ["USERNAME": user.username, "PASSWORD": user.password],
            clientId: clientId
        ))
    }

    /// `USER_PASSWORD_AUTH` for a fresh user, with its current password.
    func passwordSignIn(_ user: FreshUser) async throws -> InitiateAuthOutput {
        try await passwordSignIn(user.testUser)
    }

    /// Choice-based sign-in (`USER_AUTH`), optionally with a preferred first factor such as `EMAIL_OTP`.
    func userAuthSignIn(username: String, preferredChallenge: String? = nil) async throws -> InitiateAuthOutput {
        var parameters = ["USERNAME": username]
        if let preferredChallenge {
            parameters["PREFERRED_CHALLENGE"] = preferredChallenge
        }
        return try await client.initiateAuth(input: InitiateAuthInput(
            authFlow: .userAuth,
            authParameters: parameters,
            clientId: clientId
        ))
    }

    /// Answers one challenge of a raw sign-in.
    func respond(
        to challenge: CognitoIdentityProviderClientTypes.ChallengeNameType,
        _ responses: [String: String],
        session: String?
    ) async throws -> RespondToAuthChallengeOutput {
        try await client.respondToAuthChallenge(input: RespondToAuthChallengeInput(
            challengeName: challenge,
            challengeResponses: responses,
            clientId: clientId,
            session: session
        ))
    }

    /// Signs `user` in with the raw SDK and answers every challenge a fresh user can meet, returning its
    /// tokens: `SOFTWARE_TOKEN_MFA` (with the TOTP secret the user records), `EMAIL_OTP`, `SMS_MFA` and
    /// `SMS_OTP` (with the code from the code sink), `SELECT_MFA_TYPE` (TOTP when enrolled, else email,
    /// else SMS), and `MFA_SETUP` (by enrolling a new TOTP secret, which the user then records, or else
    /// by setting up email MFA). A user without a password signs in with `USER_AUTH` and `EMAIL_OTP`, or
    /// `SMS_OTP` when it has only a phone number.
    ///
    /// Codes are read with a sink snapshot taken before each call, so a code the test itself was sent a
    /// moment earlier is never mistaken for the new one. Device tracking adds no challenge here: no device
    /// key is sent.
    func signIn(_ user: FreshUser, sink: CodeSink? = nil) async throws -> CognitoIdentityProviderClientTypes.AuthenticationResultType {
        let sink = try sink ?? CodeSink()
        var before = try await sink.snapshot(for: user)
        var challenge: CognitoIdentityProviderClientTypes.ChallengeNameType?
        var parameters: [String: String]
        var session: String?
        if user.password != nil {
            let start = try await passwordSignIn(user)
            if let tokens = start.authenticationResult {
                return tokens
            }
            (challenge, parameters, session) = (start.challengeName, start.challengeParameters ?? [:], start.session)
        } else {
            let factor = user.email != nil ? "EMAIL_OTP" : "SMS_OTP"
            let start = try await userAuthSignIn(username: user.username, preferredChallenge: factor)
            if let tokens = start.authenticationResult {
                return tokens
            }
            (challenge, parameters, session) = (start.challengeName, start.challengeParameters ?? [:], start.session)
        }

        for _ in 0 ..< 6 {
            guard let current = challenge else {
                break
            }
            let username = parameters["USERNAME"] ?? parameters["USER_ID_FOR_SRP"] ?? user.username
            var responses = ["USERNAME": username]
            switch current {
            case .softwareTokenMfa:
                guard let secret = user.totpSecret else {
                    throw HarnessError.malformedFixture("\(user) is challenged for TOTP, but records no secret.")
                }
                responses["SOFTWARE_TOKEN_MFA_CODE"] = try await TOTP.freshCode(secret: secret)
            case .emailOtp, .smsMfa, .smsOtp:
                let kind: CodeSink.Kind = user.password == nil ? .otp : .mfa
                let code = try await sink.code(for: user, kind, after: before)
                responses[current == .smsMfa ? "SMS_MFA_CODE" : "\(current.rawValue)_CODE"] = code
            case .selectMfaType:
                let offered = Self.list(parameters["MFAS_CAN_CHOOSE"])
                let choice = user.totpSecret != nil && offered.contains("SOFTWARE_TOKEN_MFA") ? "SOFTWARE_TOKEN_MFA"
                    : offered.contains("EMAIL_OTP") ? "EMAIL_OTP" : "SMS_MFA"
                responses["ANSWER"] = choice
            case .mfaSetup:
                let offered = Self.list(parameters["MFAS_CAN_SETUP"])
                if offered.isEmpty || offered.contains("SOFTWARE_TOKEN_MFA") {
                    session = try await enrollTOTP(user, session: session)
                } else if offered.contains("EMAIL_OTP") {
                    // A user signed up without an email (MF-18) gets the address its test sets up.
                    responses["EMAIL"] = user.email ?? SandboxSignUp.setupEmail(for: user)
                } else {
                    throw HarnessError.malformedFixture("\(user) must set up MFA from \(offered), which the harness cannot.")
                }
            default:
                throw HarnessError.malformedFixture("\(user) met challenge \(current.rawValue), which the harness does not answer.")
            }
            before = try await sink.snapshot(for: user)
            let next = try await respond(to: current, responses, session: session)
            if let tokens = next.authenticationResult {
                return tokens
            }
            (challenge, parameters, session) = (next.challengeName, next.challengeParameters ?? [:], next.session)
        }
        throw HarnessError.malformedFixture("\(user)'s raw sign-in did not finish.")
    }

    // MARK: - TOTP

    /// Enrolls a new TOTP secret for a signed-in user and makes it the preferred MFA method, as the
    /// plugin's `TOTPHelper` does. The user records the secret, so `signIn(_:)` and cleanup can answer
    /// `SOFTWARE_TOKEN_MFA` afterwards.
    @discardableResult
    func enrollTOTP(_ user: FreshUser, accessToken: String) async throws -> TOTPSecret {
        let associate = try await client.associateSoftwareToken(input: AssociateSoftwareTokenInput(accessToken: accessToken))
        guard let base32 = associate.secretCode else {
            throw HarnessError.malformedFixture("AssociateSoftwareToken returned no secret.")
        }
        let secret = TOTPSecret(base32)
        let verify = try await client.verifySoftwareToken(input: VerifySoftwareTokenInput(
            accessToken: accessToken,
            friendlyDeviceName: "ccit-totp",
            userCode: TOTP.freshCode(secret: secret)
        ))
        guard verify.status == .success else {
            throw HarnessError.malformedFixture("VerifySoftwareToken did not succeed.")
        }
        user.recordTOTPSecret(secret)
        _ = try await client.setUserMFAPreference(input: SetUserMFAPreferenceInput(
            accessToken: accessToken,
            softwareTokenMfaSettings: CognitoIdentityProviderClientTypes.SoftwareTokenMfaSettingsType(enabled: true, preferredMfa: true)
        ))
        return secret
    }

    /// Answers `MFA_SETUP` by enrolling a new TOTP secret within the sign-in session, and returns the
    /// session to answer the challenge with.
    private func enrollTOTP(_ user: FreshUser, session: String?) async throws -> String? {
        let associate = try await client.associateSoftwareToken(input: AssociateSoftwareTokenInput(session: session))
        guard let base32 = associate.secretCode else {
            throw HarnessError.malformedFixture("AssociateSoftwareToken returned no secret.")
        }
        let secret = TOTPSecret(base32)
        let verify = try await client.verifySoftwareToken(input: VerifySoftwareTokenInput(
            friendlyDeviceName: "ccit-totp",
            session: associate.session,
            userCode: TOTP.freshCode(secret: secret)
        ))
        guard verify.status == .success else {
            throw HarnessError.malformedFixture("VerifySoftwareToken did not succeed.")
        }
        user.recordTOTPSecret(secret)
        return verify.session
    }

    /// A JSON array of strings in a challenge parameter, such as `MFAS_CAN_SETUP`.
    private static func list(_ parameter: String?) -> [String] {
        guard let data = parameter?.data(using: .utf8),
              let values = try? JSONSerialization.jsonObject(with: data) as? [String] else {
            return []
        }
        return values
    }
}
