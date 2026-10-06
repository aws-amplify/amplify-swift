//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Shared with CognitoClientUITests (the hosted-UI UI tests), which compiles this file and the five other
// shared sandbox helpers (IntegrationTestEnvironment, SandboxPools, SandboxSignUp, SandboxUserCleanup,
// CodeSink, TOTP) and nothing else from this folder. Keep it self-contained: it may use only those files,
// AmplifyCognitoClient (and AmplifySRP and AmplifyBigInteger, which its product builds),
// AWSCognitoIdentityProvider, Foundation, Security, CryptoKit and XCTest.
//
// AmplifySRP and AmplifyBigInteger are imported, not linked by name: Package.swift makes no product of them
// (one would publish internal modules), so a target can only reach them through a product whose closure
// holds them. AmplifyCognitoClient's does (AmplifyCognitoClient -> InternalAWSCognitoAuth -> AmplifySRP ->
// AmplifyBigInteger): SwiftPM builds and links both into every target that links the product, and Xcode
// puts their modules beside it, as for InternalAmplifyKeychain, which KeychainModuleRealKeychainTests imports
// the same way. Should the client stop depending on them, the build fails at these imports; nothing can
// fail at run time instead. Only their public API is used.

@_spi(AmplifyExperimental) import AmplifyCognitoClient
import AmplifyBigInteger
import AmplifySRP
import AWSCognitoIdentityProvider
import CryptoKit
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

    /// Whether the plugin's own setup for the role's backend promises a pre-sign-up trigger that confirms
    /// every sign-up (`autoConfirmUser`): the default and MFA-required backends
    /// (`AuthIntegrationTests/README.md`, whose hosted UI shares the default's setup and has its own in
    /// `AuthHostedUIApp/README.md`), the two email-MFA ones (`MFATests/EmailMFATests/README.md`) and the
    /// WebAuthn one (`AuthWebAuthnAppUITests/README.md`). The passwordless backend's setup
    /// (`PasswordlessTests/README.md`) deploys no trigger, and the device-alias backend's none that is
    /// written down; on the plugin's CI a fresh sign-up there comes back unconfirmed. On the sandbox every
    /// pool's trigger (P-5b) confirms all but `ccit-confirm-` users, whatever this says. A role's file can promise
    /// one too (`IntegrationTestEnvironment.promisesConfirmingTrigger(_:)`), as the client's own CI device-alias
    /// pool's does.
    var promisesConfirmingTrigger: Bool {
        ![.passwordless, .emailAlias].contains(self)
    }

    /// The features, by the names the tests require them by, that the outputs file shows the pool lacks:
    /// `sms-mfa` without `SMS` in `mfa_methods`, and, on the sandbox's file set, `email-mfa` without
    /// `EMAIL`. What the outputs do not describe (the first factors, WebAuthn, and email MFA elsewhere) is
    /// taken as live, and a test that needs it fails at Cognito.
    ///
    /// `EMAIL` is read only where the file is the sandbox's (`IntegrationTestEnvironment.isSandbox`): its
    /// `mfa_methods` are written from the pool template after `parity.py`'s `degrade()`, so they list `EMAIL`
    /// exactly when email MFA is live, and a sandbox without a usable SES identity fails the email-MFA tests
    /// naming the file. The plugin's two email-MFA backends turn email MFA on outside `defineAuth`
    /// (`MFATests/EmailMFATests/README.md`: `multifactor` names `sms`, and `totp` on the all-types one), so
    /// their outputs list `SMS` (and `TOTP`) and no `EMAIL`, and the plugin's email-MFA suites, which read no
    /// `mfa_methods`, pass on them: there email MFA is taken as live.
    func missingFeatures() throws -> [String] {
        let methods = try IntegrationTestEnvironment.outputsAuthSection(self)["mfa_methods"] as? [String] ?? []
        var missing: [String] = []
        if IntegrationTestEnvironment.isSandbox(self), !methods.contains("EMAIL") {
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
            throw HarnessError.malformedFixture("\(pool.sourceName) has no user pool.")
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
            \(pool.sourceName) shows no \(feature): the backend needs it enabled for this test.
            """)
        }
    }

    // MARK: - Raw sign-in

    /// A password sign-in with the user's current password: `USER_PASSWORD_AUTH`, or, where the app client
    /// offers no such flow (the plugin's MFA-required, email-MFA and device-alias backends), SRP
    /// (`srpSignIn(_:)`), the plugin's and the client's default flow. The answer may be a challenge.
    func passwordSignIn(_ user: TestUser) async throws -> RawSignInStep {
        do {
            return try await RawSignInStep(client.initiateAuth(input: InitiateAuthInput(
                authFlow: .userPasswordAuth,
                authParameters: ["USERNAME": user.username, "PASSWORD": user.password],
                clientId: clientId
            )))
        } catch let error as InvalidParameterException where error.message?.contains("USER_PASSWORD_AUTH") == true {
            // "USER_PASSWORD_AUTH flow not enabled for this client": Cognito refuses the flow itself,
            // before it looks at the user.
            return try await srpSignIn(user)
        }
    }

    /// A password sign-in for a fresh user, with its current password (`passwordSignIn(_:)`).
    func passwordSignIn(_ user: FreshUser) async throws -> RawSignInStep {
        try await passwordSignIn(user.testUser)
    }

    /// `USER_SRP_AUTH` with the user's current password: the `PASSWORD_VERIFIER` challenge is answered with
    /// the SRP-6a proof (`RawSRP`), and what follows it (tokens, or an MFA challenge) is returned. No device
    /// key is sent, so device tracking adds no challenge. A wrong password or a deleted user fails the
    /// answer as `USER_PASSWORD_AUTH` fails (`NotAuthorizedException`, or `UserNotFoundException` where
    /// existence errors are on), and an unconfirmed user with `UserNotConfirmedException`.
    func srpSignIn(_ user: TestUser) async throws -> RawSignInStep {
        guard let poolId = configuration.userPool?.poolId else {
            throw HarnessError.malformedFixture("\(pool.sourceName) has no user pool.")
        }
        let srp = try RawSRP()
        let start = try await client.initiateAuth(input: InitiateAuthInput(
            authFlow: .userSrpAuth,
            authParameters: ["USERNAME": user.username, "SRP_A": srp.publicAHex],
            clientId: clientId
        ))
        guard start.challengeName == .passwordVerifier else {
            return RawSignInStep(start)
        }
        let responses = try srp.passwordVerifierResponses(
            start.challengeParameters ?? [:],
            username: user.username,
            password: user.password,
            poolId: poolId
        )
        return try await RawSignInStep(respond(to: .passwordVerifier, responses, session: start.session))
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

/// Where a raw password sign-in stands after its first step (`SandboxPoolClient.passwordSignIn(_:)`):
/// `InitiateAuth` for `USER_PASSWORD_AUTH`, or the `PASSWORD_VERIFIER` answer for SRP. Tokens, or the
/// next challenge with its parameters and session.
struct RawSignInStep: Sendable {
    let authenticationResult: CognitoIdentityProviderClientTypes.AuthenticationResultType?
    let challengeName: CognitoIdentityProviderClientTypes.ChallengeNameType?
    let challengeParameters: [String: String]?
    let session: String?

    init(_ output: InitiateAuthOutput) {
        self.authenticationResult = output.authenticationResult
        self.challengeName = output.challengeName
        self.challengeParameters = output.challengeParameters
        self.session = output.session
    }

    init(_ output: RespondToAuthChallengeOutput) {
        self.authenticationResult = output.authenticationResult
        self.challengeName = output.challengeName
        self.challengeParameters = output.challengeParameters
        self.session = output.session
    }
}

/// The client side of Cognito's SRP-6a sign-in, for the raw SDK helpers: the same computation as the
/// shared engine's `VerifyPasswordSRP` (RFC 5054's 3072-bit group, `g = 2`), over the public `AmplifySRP`
/// primitives. It holds the ephemeral private value for one sign-in and never prints it or the password.
struct RawSRP {
    /// RFC 5054, appendix A, the 3072-bit group, as the engine's `SRPCommonConfig`.
    private static let nHex =
        "FFFFFFFFFFFFFFFFC90FDAA22168C234C4C6628B80DC1CD129024E088A67CC74020BBEA63B139B2" +
        "2514A08798E3404DDEF9519B3CD3A431B302B0A6DF25F14374FE1356D6D51C245E485B576625E7E" +
        "C6F44C42E9A637ED6B0BFF5CB6F406B7EDEE386BFB5A899FA5AE9F24117C4B1FE649286651ECE45" +
        "B3DC2007CB8A163BF0598DA48361C55D39A69163FA8FD24CF5F83655D23DCA3AD961C62F3562085" +
        "52BB9ED529077096966D670C354E4ABC9804F1746C08CA18217C32905E462E36CE3BE39E772C180" +
        "E86039B2783A2EC07A28FB5C55DF06F4C52C9DE2BCBF6955817183995497CEA956AE515D2261898" +
        "FA051015728E5A8AAAC42DAD33170D04507A33A85521ABDF1CBA64ECFB850458DBEF0A8AEA71575" +
        "D060C7DB3970F85A6E1E4C7ABF5AE8CDB0933D71E8C94E04A25619DCEE3D2261AD2EE6BF12FFA06" +
        "D98A0864D87602733EC86A64521F2B18177B200CBBE117577A615D6C770988C0BAD946E208E24FA" +
        "074E5AB3143DB5BFCE0FD108E4B82D120A93AD2CAFFFFFFFFFFFFFFFF"

    private let common: SRPCommonState
    private let state: SRPClientState

    init() throws {
        guard let prime = AmplifyBigInt(Self.nHex, radix: 16), let generator = AmplifyBigInt("2", radix: 16) else {
            throw HarnessError.malformedFixture("The SRP group does not parse.")
        }
        self.common = SRPCommonState(prime: prime, generator: generator)
        self.state = SRPClientState(commonState: common)
    }

    /// `SRP_A`, the client's public value, in hex.
    var publicAHex: String {
        state.publicA.asString(radix: 16)
    }

    /// The `PASSWORD_VERIFIER` answer: `USERNAME`, `PASSWORD_CLAIM_SECRET_BLOCK`, `PASSWORD_CLAIM_SIGNATURE`
    /// and `TIMESTAMP`, from the challenge's `SALT`, `SRP_B`, `SECRET_BLOCK` and `USER_ID_FOR_SRP`.
    func passwordVerifierResponses(
        _ parameters: [String: String],
        username: String,
        password: String,
        poolId: String
    ) throws -> [String: String] {
        guard let saltHex = parameters["SALT"], let salt = AmplifyBigInt(saltHex, radix: 16),
              let serverBHex = parameters["SRP_B"], let serverB = AmplifyBigInt(serverBHex, radix: 16),
              let secretBlockString = parameters["SECRET_BLOCK"],
              let secretBlock = Data(base64Encoded: secretBlockString) else {
            throw HarnessError.malformedFixture("PASSWORD_VERIFIER came without a usable SALT, SRP_B or SECRET_BLOCK.")
        }
        guard serverB % common.prime != AmplifyBigInt(0) else {
            throw HarnessError.malformedFixture("PASSWORD_VERIFIER came with an illegal SRP_B.")
        }
        let userIdForSRP = parameters["USER_ID_FOR_SRP"] ?? username
        // The pool id without its region prefix, as Cognito hashes it into x and the signature.
        let poolName = poolId.split(separator: "_", maxSplits: 1).last.map(String.init) ?? poolId
        let sharedSecret = SRPClientState.calculateSessionKey(
            username: "\(poolName)\(userIdForSRP)",
            password: password,
            publicClientKey: state.publicA,
            privateClientKey: state.privateA,
            publicServerKey: serverB,
            salt: salt,
            commonState: common
        )
        let u = SRPClientState.calculcateU(
            publicClientKey: AmplifyBigIntHelper.getSignedData(num: state.publicA),
            publicServerKey: AmplifyBigIntHelper.getSignedData(num: serverB)
        )
        let key = HMACKeyDerivationFunction.generateDerivedKey(
            keyingMaterial: Data(AmplifyBigIntHelper.getSignedData(num: sharedSecret)),
            salt: Data(AmplifyBigIntHelper.getSignedData(num: u)),
            info: "Caldera Derived Key",
            outputLength: 16
        )
        let timestamp = Self.timestamp(Date())
        var hmac = HMAC<SHA256>(key: SymmetricKey(data: key))
        hmac.update(data: Data(poolName.utf8))
        hmac.update(data: Data(userIdForSRP.utf8))
        hmac.update(data: secretBlock)
        hmac.update(data: Data(timestamp.utf8))
        return [
            "USERNAME": parameters["USERNAME"] ?? username,
            "PASSWORD_CLAIM_SECRET_BLOCK": secretBlockString,
            "PASSWORD_CLAIM_SIGNATURE": Data(hmac.finalize()).base64EncodedString(),
            "TIMESTAMP": timestamp
        ]
    }

    /// Cognito's SRP timestamp, `EEE MMM d HH:mm:ss 'UTC' yyyy` in UTC and the POSIX locale.
    private static func timestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE MMM d HH:mm:ss 'UTC' yyyy"
        return formatter.string(from: date)
    }
}
