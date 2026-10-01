//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyCognitoClient
import AWSCognitoIdentity
import AWSCognitoIdentityProvider
import Foundation
import Security
import XCTest

/// Each plugin-parity resource (P-5 … P-11) is reachable and behaves as provisioned.
///
/// Like `SandboxProvisioningTests`, these talk to Cognito through plain SDK clients, independently of the
/// client under test, so a failure points at provisioning. They need no AWS credentials: sign-up and
/// sign-in on a public app client are unauthenticated calls. Users are fresh (`ccit-<hex>`, with an
/// `@example.com` address). Every user that signs up is deleted at teardown, however the test ends:
/// through `SandboxUserCleanup`, which answers each pool's MFA, so a user whose sign-in stopped at an MFA
/// challenge is deleted too. `prepare-run.sh` removes any left over after 24 hours (P-12). No assertion prints an identifier or a secret.
///
/// A feature a pool's outputs show it lacks (no `SMS` in its `mfa_methods`) fails the test that needs it,
/// with a message naming the file (`requireLive`); a check that only observes a feature (the choice-based
/// sign-in's offered factors) checks the form the outputs describe.
///
/// On the plugin's CI backends these check what those backends promise: password sign-ins fall back to
/// SRP where an app client offers no `USER_PASSWORD_AUTH`, a user a pool leaves unconfirmed is confirmed
/// with its code, and codes are the first sent after the request. What only the sandbox provisions (a
/// trigger that refuses users who are not test users, say) is a sandbox check: it runs on the sandbox's file
/// set (`IntegrationTestEnvironment.isSandbox`) and elsewhere skips, saying so.
final class SandboxParityProvisioningTests: XCTestCase {

    /// Every parity outputs file loads, and each names its own pool.
    ///
    /// - Given: The plugin's outputs file for each role (or the Gen2 translation of its Gen1 file), copied into
    ///   the bundle
    /// - When:
    ///    - Each is loaded with `AuthClientConfiguration(from:bundle:)`, and the identity-only role is derived
    /// - Then:
    ///    - Each has a user pool; the seven roles with users of their own are seven distinct pools, and the
    ///      hosted-UI file names a different app client from the default one, on the default pool (the
    ///      sandbox's set) or on a pool of its own (a backend of its own), never another role's
    ///    - The identity-only role has an identity pool and no user pool, and its guest access is on, or not
    ///      stated where the default backend is a Gen1 file, which has no such key (whether guests get
    ///      credentials is `testIdentityOnlyPoolVendsGuestCredentials`' check)
    ///
    func testEveryParityOutputsFileLoads() throws {
        var poolIds: [SandboxPool: String] = [:]
        var clientIds: [SandboxPool: String] = [:]
        for pool in SandboxPool.allCases {
            let userPool = try XCTUnwrap(IntegrationTestEnvironment.configuration(pool).userPool, "\(pool)")
            poolIds[pool] = userPool.poolId
            clientIds[pool] = userPool.appClientId
        }
        let rolePools = poolIds.filter { $0.key != .hostedUI }
        XCTAssertEqual(Set(rolePools.values).count, 7, "The seven roles' pools are not distinct")
        let hostedPool = try XCTUnwrap(poolIds[.hostedUI])
        XCTAssertTrue(
            hostedPool == poolIds[.standard] || !rolePools.values.contains(hostedPool),
            "hosted-ui is on another role's pool"
        )
        XCTAssertFalse(clientIds[.hostedUI] == clientIds[.standard], "hosted-ui reuses the default client")

        let identityOnly = try IntegrationTestEnvironment.identityOnlyAuthSection()
        XCTAssertNil(identityOnly["user_pool_id"])
        XCTAssertFalse((identityOnly["identity_pool_id"] as? String ?? "").isEmpty)
        let guestAccess = identityOnly["unauthenticated_identities_enabled"] as? Bool
        if case .gen2 = PluginTestConfiguration.source(SandboxPool.standard.outputsResource, in: IntegrationTestEnvironment.bundle) {
            XCTAssertEqual(guestAccess, true)
        } else {
            XCTAssertNil(guestAccess, "a Gen1 file states no guest access")
        }
    }

    /// The default pool auto-confirms a sign-up (pre-sign-up trigger) and tracks devices (U-DEF, P-5b).
    ///
    /// - Given: The default pool, whose pre-sign-up Lambda confirms every user not named `confirm-…`
    /// - When:
    ///    - A fresh user signs up with an email, then signs in with its password (`USER_PASSWORD_AUTH`, which
    ///      the default backend's app client offers, or SRP where a client does not: `ParityPool.passwordSignIn`)
    /// - Then:
    ///    - The sign-up is confirmed straight away
    ///    - The sign-in returns tokens and new-device metadata (device tracking is always on)
    ///
    func testDefaultPoolAutoConfirmsSignUpAndTracksDevices() async throws {
        let pool = try ParityPool(.standard)
        let user = ParityPool.freshUser()

        let signUp = try await pool.signUp(user, deletingAtTeardownOf: self)
        XCTAssertTrue(signUp.userConfirmed)

        let signIn = try await pool.passwordSignIn(user)
        pool.deleteAtTeardown(signIn.authenticationResult, of: self)
        XCTAssertNil(signIn.challengeName)
        XCTAssertNotNil(signIn.authenticationResult?.newDeviceMetadata?.deviceKey)
    }

    /// The pre-sign-up trigger refuses a sign-up that is not a test user (P-5b).
    ///
    /// A sandbox check: the refusal is the sandbox's own safeguard. The plugin's default backend's trigger
    /// only confirms (its README), so on a file set that is not the sandbox's
    /// (`IntegrationTestEnvironment.isSandbox`) it skips, saying so, rather than sign such a user up there.
    ///
    /// - Given: The sandbox's default pool, whose pre-sign-up Lambda accepts only `ccit-` and `confirm-`
    ///   usernames
    /// - When:
    ///    - A user named without either prefix signs up
    /// - Then:
    ///    - Cognito rejects it with `UserLambdaValidationException`, so no such user is created
    ///
    func testPreSignUpRefusesUsersThatAreNotTestUsers() async throws {
        try IntegrationTestEnvironment.requireSandbox(
            .standard,
            "a pre-sign-up trigger that refuses users who are not test users"
        )
        let pool = try ParityPool(.standard)
        let fresh = ParityPool.freshUser()
        let outsider = TestUser(username: "outsider-" + fresh.username.dropFirst("ccit-".count), password: fresh.password)

        do {
            _ = try await pool.signUp(outsider, email: fresh.email, deletingAtTeardownOf: self)
            XCTFail("A sign-up without a test prefix was accepted")
        } catch is UserLambdaValidationException {
            // Expected: the trigger threw.
        }
    }

    /// Custom auth without SRP completes with the stored answer (define/create/verify triggers, P-5b).
    ///
    /// - Given: A fresh, auto-confirmed user on the default pool, and the credentials file's
    ///   `custom_challenge_answer`
    /// - When:
    ///    - It starts `CUSTOM_AUTH` with its username only, and answers the challenge
    /// - Then:
    ///    - The start returns `CUSTOM_CHALLENGE`, and the answer returns tokens
    ///
    func testCustomAuthCompletesWithTheStoredAnswer() async throws {
        let pool = try ParityPool(.standard)
        let user = ParityPool.freshUser()
        _ = try await pool.signUp(user, deletingAtTeardownOf: self)
        let answer = try IntegrationTestEnvironment.credentials().requireCustomChallengeAnswer()

        let start = try await pool.client.initiateAuth(input: InitiateAuthInput(
            authFlow: .customAuth,
            authParameters: ["USERNAME": user.username],
            clientId: pool.clientId
        ))
        XCTAssertEqual(start.challengeName, .customChallenge)
        let result = try await pool.client.respondToAuthChallenge(input: RespondToAuthChallengeInput(
            challengeName: .customChallenge,
            challengeResponses: ["USERNAME": user.username, "ANSWER": answer.value],
            clientId: pool.clientId,
            session: start.session
        ))
        pool.deleteAtTeardown(result.authenticationResult, of: self)
        XCTAssertNotNil(result.authenticationResult?.accessToken)
    }

    /// A sign-up confirmation code reaches the code sink and confirms the user (P-5a, P-5c).
    ///
    /// - Given: The passwordless pool (U-PL), whose custom email sender decrypts codes with the KMS key and
    ///   publishes them to the code API its outputs name, and which leaves the sign-up to confirm: the
    ///   plugin's passwordless backend has no pre-sign-up trigger, and the sandbox's leaves `ccit-confirm-`
    ///   users unconfirmed
    /// - When:
    ///    - A fresh `ccit-confirm-…` user (not auto-confirmed) signs up with an `@example.com` address
    ///    - The test reads the newest code for the username from the code API
    /// - Then:
    ///    - The sign-up is unconfirmed, a code arrives, and `ConfirmSignUp` accepts it
    ///
    func testSignUpCodeReachesTheCodeSinkAndConfirms() async throws {
        let pool = try ParityPool(.passwordless)
        let sink = try CodeSink()
        let user = ParityPool.freshUser(needsConfirmation: true)
        let since = Date()

        let signUp = try await pool.signUp(user, deletingAtTeardownOf: self)
        XCTAssertFalse(signUp.userConfirmed)
        let code = try await sink.code(for: user.username, on: pool.kind, since: since)

        _ = try await pool.client.confirmSignUp(input: ConfirmSignUpInput(
            clientId: pool.clientId,
            confirmationCode: code,
            username: user.username
        ))
        let signIn = try await pool.passwordSignIn(user)
        pool.deleteAtTeardown(signIn.authenticationResult, of: self)
        XCTAssertNotNil(signIn.authenticationResult?.accessToken)
    }

    /// The passwordless pool offers choice-based sign-in (U-PL).
    ///
    /// - Given: A fresh, auto-confirmed user on the passwordless pool, with an email and a fictional `+1 555` phone number
    /// - When:
    ///    - It starts `USER_AUTH` with its username only
    /// - Then:
    ///    - Cognito answers `SELECT_CHALLENGE`, offering `PASSWORD`, plus `EMAIL_OTP` and `SMS_OTP`
    ///
    func testPasswordlessPoolOffersChoiceBasedSignIn() async throws {
        let pool = try ParityPool(.passwordless)
        let user = ParityPool.freshUser()
        _ = try await pool.signUp(user, phoneNumber: ParityPool.fictionalPhoneNumber(), deletingAtTeardownOf: self)

        let start = try await pool.client.initiateAuth(input: InitiateAuthInput(
            authFlow: .userAuth,
            authParameters: ["USERNAME": user.username],
            clientId: pool.clientId
        ))
        XCTAssertEqual(start.challengeName, .selectChallenge)
        let offered = Set((start.availableChallenges ?? []).map(\.rawValue))
        XCTAssertTrue(offered.contains("PASSWORD"), "Offered \(offered.sorted())")
        XCTAssertTrue(offered.contains("EMAIL_OTP"), "Offered \(offered.sorted())")
        XCTAssertTrue(offered.contains("SMS_OTP"), "Offered \(offered.sorted())")
    }

    /// The WebAuthn pool starts a passkey registration for the harness's relying party (U-WA, P-10).
    ///
    /// - Given: A fresh, auto-confirmed user on the WebAuthn pool, signed in with its password
    /// - When:
    ///    - It calls `StartWebAuthnRegistration` with its access token
    /// - Then:
    ///    - Cognito returns credential creation options whose relying party is the domain the WebAuthn
    ///      UI-test app's `webcredentials:` entitlement names, and whose user is this user. This is what
    ///      WA-0 and WA-1 need from the backend; the passkey itself needs the simulator (the UI tests)
    ///
    func testWebAuthnPoolStartsARegistrationForTheHarnessRelyingParty() async throws {
        let pool = try ParityPool(.webAuthn)
        try pool.requireLive("web-authn")
        let user = ParityPool.freshUser()
        _ = try await pool.signUp(user, deletingAtTeardownOf: self)
        let signIn = try await pool.passwordSignIn(user)
        pool.deleteAtTeardown(signIn.authenticationResult, of: self)
        let accessToken = try XCTUnwrap(signIn.authenticationResult?.accessToken)

        let start = try await pool.client.startWebAuthnRegistration(input: StartWebAuthnRegistrationInput(
            accessToken: accessToken
        ))
        let options = try XCTUnwrap(start.credentialCreationOptions?.asStringMap())
        // A boolean, so a failure does not print the domain.
        let rpId = try options["rp"]?.asStringMap()["id"]?.asString()
        let harnessRP = try Self.harnessRelyingParty()
        XCTAssertTrue(rpId == harnessRP, "rp.id is not the harness relying party")
        XCTAssertEqual(try options["user"]?.asStringMap()["name"]?.asString(), user.username)
        XCTAssertNotNil(try options["challenge"]?.asString())
    }

    /// The relying party in `CognitoClientWebAuthnApp.entitlements` (the plugin's, committed), read from the copy the
    /// build puts in this bundle: the same file `infra/parity.py` reads the pool's relying party from.
    private static func harnessRelyingParty() throws -> String {
        let name = "CognitoClientWebAuthnApp.entitlements"
        guard let url = IntegrationTestEnvironment.bundle.url(
            forResource: "CognitoClientWebAuthnApp",
            withExtension: "entitlements"
        ) else {
            throw HarnessError.malformedFixture(
                "\(name) is not in the test bundle: the \"Copy sandbox configuration\" phase copies it from "
                    + "CognitoClientHostApp/. Rebuild the CognitoClientIntegrationTests target."
            )
        }
        let plist = try PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil)
        let domains = (plist as? [String: Any])?["com.apple.developer.associated-domains"] as? [String] ?? []
        let web = domains.filter { $0.hasPrefix("webcredentials:") }
        guard web.count == 1, let domain = web[0].dropFirst("webcredentials:".count).split(separator: "?").first else {
            throw HarnessError.malformedFixture("\(name) names \(web.count) webcredentials domains, not 1")
        }
        return String(domain)
    }

    /// The MFA-required pools challenge a fresh user for MFA (U-REQ-TS, U-REQ-E, U-REQ-ALL).
    ///
    /// - Given: A fresh, auto-confirmed user with no MFA set up, on each MFA-required pool
    /// - When:
    ///    - It signs in with its password (`USER_PASSWORD_AUTH`, or SRP where the app client offers no
    ///      password flow, as on the plugin's MFA-required backends)
    /// - Then:
    ///    - It is challenged (`MFA_SETUP`, or an email or SMS code when those factors are live)
    ///    - A challenge that sends a code has delivered it to the code API before the test ends: the first
    ///      code sent after the sign-in started. Waiting for it is also what lets the teardown delete the
    ///      user: its sign-in answers the challenge with the first code that was not in the sink before it
    ///      started, which must not be this one
    ///
    func testMFARequiredPoolsChallengeAFreshUser() async throws {
        let sink = try CodeSink()
        for kind in [SandboxPool.mfaRequiredTOTPSMS, .mfaRequiredEmail, .mfaRequiredAll] {
            let pool = try ParityPool(kind)
            let user = ParityPool.freshUser()
            _ = try await pool.signUp(user, deletingAtTeardownOf: self)
            let before = try await sink.snapshot(for: user.username, on: kind)

            let signIn = try await pool.passwordSignIn(user)
            pool.deleteAtTeardown(signIn.authenticationResult, of: self)
            let challenge = try XCTUnwrap(signIn.challengeName, "\(kind) issued tokens without MFA")
            XCTAssertTrue(
                [.mfaSetup, .emailOtp, .smsMfa, .selectMfaType].contains(challenge),
                "\(kind) challenged with \(challenge)"
            )
            XCTAssertNil(signIn.authenticationResult, "\(kind)")
            if [.emailOtp, .smsMfa].contains(challenge) {
                _ = try await sink.code(for: user.username, on: kind, after: before)
            }
        }
    }

    /// An email MFA code reaches the code sink and completes a required-MFA sign-in (U-REQ-E, P-8).
    ///
    /// - Given: The email-MFA-required pool, with DEVELOPER email and the custom email sender, and a
    ///   fresh user whose `@example.com` address the pre-sign-up trigger verified
    /// - When:
    ///    - The user signs in with its password (`USER_PASSWORD_AUTH`, or SRP where the app client offers
    ///      no password flow, as on the plugin's email-MFA backends)
    ///    - The test reads the first code for the username the code API received after the sign-in
    ///      started, and answers with it
    /// - Then:
    ///    - The sign-in is challenged with `EMAIL_OTP`, and the captured code returns tokens
    ///
    func testEmailMFACodeReachesTheCodeSinkAndCompletesSignIn() async throws {
        let pool = try ParityPool(.mfaRequiredEmail)
        try pool.requireLive("email-mfa")
        let sink = try CodeSink()
        let user = ParityPool.freshUser()
        _ = try await pool.signUp(user, deletingAtTeardownOf: self)

        let (start, code) = try await sink.code(for: user.username, on: pool.kind) {
            try await pool.passwordSignIn(user)
        }
        XCTAssertEqual(start.challengeName, .emailOtp)
        let result = try await pool.client.respondToAuthChallenge(input: RespondToAuthChallengeInput(
            challengeName: .emailOtp,
            challengeResponses: ["USERNAME": user.username, "EMAIL_OTP_CODE": code],
            clientId: pool.clientId,
            session: start.session
        ))
        pool.deleteAtTeardown(result.authenticationResult, of: self)
        XCTAssertNotNil(result.authenticationResult?.accessToken)
    }

    /// An `EMAIL_OTP` first-factor code reaches the code sink and completes a passwordless sign-in (U-PL).
    ///
    /// - Given: The passwordless pool, with `EMAIL_OTP` allowed as a first factor, and a fresh user with
    ///   a verified `@example.com` address
    /// - When:
    ///    - The user starts `USER_AUTH` preferring `EMAIL_OTP`, and answers with the first code the sink
    ///      received after the start (on a pool without a pre-sign-up trigger, such as the plugin's, the
    ///      user was confirmed with a sign-up code moments before)
    /// - Then:
    ///    - The start is challenged with `EMAIL_OTP`, and the captured code returns tokens
    ///
    func testEmailOTPCodeReachesTheCodeSinkAndCompletesPasswordlessSignIn() async throws {
        let pool = try ParityPool(.passwordless)
        try pool.requireLive("email-otp")
        let sink = try CodeSink()
        let user = ParityPool.freshUser()
        _ = try await pool.signUp(user, deletingAtTeardownOf: self)

        let (start, code) = try await sink.code(for: user.username, on: pool.kind) {
            try await pool.client.initiateAuth(input: InitiateAuthInput(
                authFlow: .userAuth,
                authParameters: ["USERNAME": user.username, "PREFERRED_CHALLENGE": "EMAIL_OTP"],
                clientId: pool.clientId
            ))
        }
        XCTAssertEqual(start.challengeName, .emailOtp)
        let result = try await pool.client.respondToAuthChallenge(input: RespondToAuthChallengeInput(
            challengeName: .emailOtp,
            challengeResponses: ["USERNAME": user.username, "EMAIL_OTP_CODE": code],
            clientId: pool.clientId,
            session: start.session
        ))
        pool.deleteAtTeardown(result.authenticationResult, of: self)
        XCTAssertNotNil(result.authenticationResult?.accessToken)
    }

    /// An SMS MFA code reaches the code sink and completes a required-MFA sign-in (U-REQ-ALL, P-9).
    ///
    /// - Given: The all-types MFA-required pool (TOTP, SMS and email; the MFA-required pool closest to
    ///   U-REQ-TS whose outputs name a code API), with the SNS caller role and the custom SMS sender, and a
    ///   fresh user whose fictional `+1 555` number the pre-sign-up trigger verified
    /// - When:
    ///    - The user signs in with its password (`USER_PASSWORD_AUTH`, or SRP where the app client offers
    ///      no password flow, as on the plugin's all-types backend), choosing SMS if Cognito asks which
    ///      factor
    ///    - The test reads the first code for the username the code API received after the sign-in
    ///      started, and answers with it
    /// - Then:
    ///    - The sign-in is challenged with `SMS_MFA`, and the captured code returns tokens
    ///
    func testSMSMFACodeReachesTheCodeSinkAndCompletesSignIn() async throws {
        let pool = try ParityPool(.mfaRequiredAll)
        try pool.requireLive("sms-mfa")
        let sink = try CodeSink()
        let user = ParityPool.freshUser()
        _ = try await pool.signUp(user, phoneNumber: ParityPool.fictionalPhoneNumber(), deletingAtTeardownOf: self)
        let before = try await sink.snapshot(for: user.username, on: pool.kind)

        let start = try await pool.passwordSignIn(user)
        var challengeName = start.challengeName
        var session = start.session
        if challengeName == .selectMfaType {
            let selected = try await pool.client.respondToAuthChallenge(input: RespondToAuthChallengeInput(
                challengeName: .selectMfaType,
                challengeResponses: ["USERNAME": user.username, "ANSWER": "SMS_MFA"],
                clientId: pool.clientId,
                session: session
            ))
            challengeName = selected.challengeName
            session = selected.session
        }
        XCTAssertEqual(challengeName, .smsMfa)
        let code = try await sink.code(for: user.username, on: pool.kind, after: before)
        let result = try await pool.client.respondToAuthChallenge(input: RespondToAuthChallengeInput(
            challengeName: .smsMfa,
            challengeResponses: ["USERNAME": user.username, "SMS_MFA_CODE": code],
            clientId: pool.clientId,
            session: session
        ))
        pool.deleteAtTeardown(result.authenticationResult, of: self)
        XCTAssertNotNil(result.authenticationResult?.accessToken)
    }

    /// An `SMS_OTP` first-factor code reaches the code sink and completes a passwordless sign-in (U-PL, P-9).
    ///
    /// - Given: The passwordless pool, with `SMS_OTP` allowed as a first factor, and a fresh user with a
    ///   verified fictional `+1 555` number
    /// - When:
    ///    - The user starts `USER_AUTH` preferring `SMS_OTP`, and answers with the first code the sink
    ///      received after the start (on a pool without a pre-sign-up trigger, such as the plugin's, the
    ///      user was confirmed with a sign-up code moments before)
    /// - Then:
    ///    - The start is challenged with `SMS_OTP`, and the captured code returns tokens
    ///
    func testSMSOTPCodeReachesTheCodeSinkAndCompletesPasswordlessSignIn() async throws {
        let pool = try ParityPool(.passwordless)
        try pool.requireLive("sms-otp")
        let sink = try CodeSink()
        let user = ParityPool.freshUser()
        _ = try await pool.signUp(user, phoneNumber: ParityPool.fictionalPhoneNumber(), deletingAtTeardownOf: self)

        let (start, code) = try await sink.code(for: user.username, on: pool.kind) {
            try await pool.client.initiateAuth(input: InitiateAuthInput(
                authFlow: .userAuth,
                authParameters: ["USERNAME": user.username, "PREFERRED_CHALLENGE": "SMS_OTP"],
                clientId: pool.clientId
            ))
        }
        XCTAssertEqual(start.challengeName, .smsOtp)
        let result = try await pool.client.respondToAuthChallenge(input: RespondToAuthChallengeInput(
            challengeName: .smsOtp,
            challengeResponses: ["USERNAME": user.username, "SMS_OTP_CODE": code],
            clientId: pool.clientId,
            session: start.session
        ))
        pool.deleteAtTeardown(result.authenticationResult, of: self)
        XCTAssertNotNil(result.authenticationResult?.accessToken)
    }

    /// The email-alias pool signs in by email, tracks devices, and issues 5-minute tokens (U-ALIAS).
    ///
    /// - Given: The email-alias pool (email is the username attribute)
    /// - When:
    ///    - A fresh user signs up with an email as its username, then signs in with that email and its
    ///      password (SRP where the app client offers no password flow, as on the plugin's backend)
    /// - Then:
    ///    - The user is confirmed: on the sandbox by its pre-sign-up trigger (a sandbox check), elsewhere by
    ///      that or with its sign-up code, as `ParityPool.signUp` confirms it
    ///    - The sign-in returns tokens and new-device metadata
    ///    - The access token lives 300 seconds (299 allowed), and its username is not the email (Cognito generates it)
    ///
    func testEmailAliasPoolSignsInByEmailWithShortTokens() async throws {
        let pool = try ParityPool(.emailAlias)
        let fresh = ParityPool.freshUser()
        let user = TestUser(username: fresh.email, password: fresh.password)

        let signUp = try await pool.signUp(user, email: fresh.email, deletingAtTeardownOf: self)
        if IntegrationTestEnvironment.isSandbox(.emailAlias) {
            XCTAssertTrue(signUp.userConfirmed, "the sandbox's pre-sign-up trigger did not confirm the sign-up")
        }
        let signIn = try await pool.passwordSignIn(user)
        pool.deleteAtTeardown(signIn.authenticationResult, of: self)

        let tokens = try XCTUnwrap(signIn.authenticationResult)
        XCTAssertNotNil(tokens.newDeviceMetadata?.deviceKey)
        let claims = try IntegrationTestEnvironment.jwtClaims(XCTUnwrap(tokens.accessToken))
        let lifetime = try XCTUnwrap(claims["exp"] as? Double) - XCTUnwrap(claims["iat"] as? Double)
        // Cognito's `exp` - `iat` is sometimes a second short of the validity (299 once in
        // `client-final-3x.md`, run T2), so allow that one second. The default validity is an hour.
        XCTAssertTrue((299 ... 300).contains(lifetime), "The access token lives \(lifetime) s, not 5 minutes")
        XCTAssertFalse((claims["username"] as? String) == fresh.email, "The username is the email")
    }

    /// The hosted-UI domain serves the managed login page for the hosted-UI client (P-7).
    ///
    /// - Given: The hosted-UI outputs file, with its `oauth` block
    /// - When:
    ///    - The test requests `/login` on the domain with the client, the code grant and the file's callback
    /// - Then:
    ///    - The block lists one callback and one sign-out URI, each in a URL scheme the hosted-UI host app
    ///      registers (`CognitoClientHostedUIApp-Info.plist`: the plugin's `myapp`, and `cognitoclienthostapp`),
    ///      and the page answers HTTP 200
    ///
    func testHostedUIDomainServesTheLoginPage() async throws {
        let auth = try IntegrationTestEnvironment.outputsAuthSection(SandboxPool.hostedUI)
        let oauth = try XCTUnwrap(auth["oauth"] as? [String: Any])
        let signIn = try XCTUnwrap((oauth["redirect_sign_in_uri"] as? [String])?.first)
        let signOut = try XCTUnwrap((oauth["redirect_sign_out_uri"] as? [String])?.first)
        XCTAssertEqual((oauth["redirect_sign_in_uri"] as? [String])?.count, 1)
        XCTAssertEqual((oauth["redirect_sign_out_uri"] as? [String])?.count, 1)
        for uri in [signIn, signOut] {
            XCTAssertTrue(
                ["myapp", "cognitoclienthostapp"].contains(URL(string: uri)?.scheme ?? ""),
                "the hosted-UI app does not register the redirect's scheme"
            )
        }
        XCTAssertEqual(oauth["response_type"] as? String, "code")
        let domain = try XCTUnwrap(oauth["domain"] as? String)
        let clientId = try XCTUnwrap(auth["user_pool_client_id"] as? String)

        var components = URLComponents()
        components.scheme = "https"
        components.host = domain
        components.path = "/login"
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "openid"),
            URLQueryItem(name: "redirect_uri", value: signIn)
        ]
        let url = try XCTUnwrap(components.url)
        let response: URLResponse
        do {
            (_, response) = try await URLSession.shared.data(from: url)
        } catch let error as URLError {
            // A URLError's description and userInfo carry the URL, which names the domain and the
            // client: report only the code.
            throw HarnessError.malformedFixture("The hosted-UI login page request failed: URLError \(error.code.rawValue).")
        } catch {
            throw HarnessError.malformedFixture("The hosted-UI login page request failed.")
        }
        XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
    }

    /// The identity-only identity pool vends guest credentials (P-6′).
    ///
    /// - Given: The identity-only role (the default backend's identity pool, derived without its user pool),
    ///   with guest access
    /// - When:
    ///    - The test calls `GetId` and `GetCredentialsForIdentity` without logins
    /// - Then:
    ///    - It gets an identity and complete, unexpired AWS credentials
    ///
    func testIdentityOnlyPoolVendsGuestCredentials() async throws {
        let auth = try IntegrationTestEnvironment.identityOnlyAuthSection()
        let region = try XCTUnwrap(auth["aws_region"] as? String)
        let identityPoolId = try XCTUnwrap(auth["identity_pool_id"] as? String)
        let client = try await CognitoIdentityClient(
            config: CognitoIdentityClient.CognitoIdentityClientConfiguration(region: region)
        )

        let getId = try await client.getId(input: GetIdInput(identityPoolId: identityPoolId))
        let identityId = try XCTUnwrap(getId.identityId)
        let output = try await client.getCredentialsForIdentity(input: GetCredentialsForIdentityInput(
            identityId: identityId
        ))
        let credentials = try XCTUnwrap(output.credentials)
        XCTAssertFalse(credentials.accessKeyId?.isEmpty ?? true, "No access key id")
        XCTAssertFalse(credentials.sessionToken?.isEmpty ?? true, "No session token")
        XCTAssertGreaterThan(try XCTUnwrap(credentials.expiration), Date())
    }

    /// The third keychain access group is entitled and usable (P-11).
    ///
    /// - Given: `CognitoClientHostApp.entitlements`, with the `…Shared2` group
    /// - When:
    ///    - An item is written to that group, read back, and deleted
    /// - Then:
    ///    - Each call succeeds, and the item is found only in that group
    ///
    func testThirdKeychainAccessGroupIsUsable() throws {
        let group = try IntegrationTestEnvironment.secondSharedAccessGroup()
        let service = "com.amplify.cognitoClient.integration.shared2.\(UUID().uuidString)"
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: "probe",
            kSecUseDataProtectionKeychain as String: true
        ]
        var add = base
        add[kSecAttrAccessGroup as String] = group
        add[kSecValueData as String] = Data("probe".utf8)
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        XCTAssertEqual(SecItemAdd(add as CFDictionary, nil), errSecSuccess)
        defer { SecItemDelete(base as CFDictionary) }

        XCTAssertEqual(try IntegrationTestEnvironment.rawKeychainAccounts(service: service, accessGroup: group), ["probe"])
        XCTAssertEqual(
            try IntegrationTestEnvironment.rawKeychainAccounts(
                service: service,
                accessGroup: IntegrationTestEnvironment.sharedAccessGroup()
            ),
            []
        )
        var delete = base
        delete[kSecAttrAccessGroup as String] = group
        XCTAssertEqual(SecItemDelete(delete as CFDictionary), errSecSuccess)
    }
}

/// A plain SDK client for one parity pool's app client.
private struct ParityPool {
    let kind: SandboxPool
    let client: CognitoIdentityProviderClient
    let clientId: String
    init(_ kind: SandboxPool) throws {
        let userPool = try XCTUnwrap(IntegrationTestEnvironment.configuration(kind).userPool)
        self.kind = kind
        self.clientId = userPool.appClientId
        self.client = try CognitoIdentityProviderClient(
            config: CognitoIdentityProviderClient.CognitoIdentityProviderClientConfig(region: userPool.region)
        )
    }

    /// Fails (never skips) when the pool's outputs show it lacks `feature` (`SandboxPoolClient.requireLive`).
    func requireLive(_ feature: String) throws {
        try SandboxPoolClient(kind).requireLive(feature)
    }

    /// A user no test or earlier run has used: `ccit-<12 hex>`, or `ccit-confirm-<12 hex>` for one the
    /// pre-sign-up trigger leaves unconfirmed. Its password meets every parity pool's policy.
    static func freshUser(needsConfirmation: Bool = false) -> (username: String, password: String, email: String) {
        let hex = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(12).lowercased()
        let username = needsConfirmation ? "ccit-confirm-\(hex)" : "ccit-\(hex)"
        return (username, "Ccit-\(UUID().uuidString)-1!", "\(username)@example.com")
    }

    /// A fictional phone number: `+1 555` then seven random digits. Area code 555 is not assigned, and
    /// every SMS-enabled pool's custom sender captures the code, so nothing is ever sent.
    static func fictionalPhoneNumber() -> String {
        "+1555" + String(format: "%07d", Int.random(in: 0 ..< 10_000_000))
    }

    /// Signs `user` up, and registers its deletion as a teardown block of `testCase` straight away.
    func signUp(
        _ user: (username: String, password: String, email: String),
        phoneNumber: String? = nil,
        deletingAtTeardownOf testCase: XCTestCase
    ) async throws -> SignUpOutput {
        try await signUp(
            TestUser(username: user.username, password: user.password),
            email: user.email,
            phoneNumber: phoneNumber,
            deletingAtTeardownOf: testCase
        )
    }

    /// Signs `user` up, and, once Cognito has created it, registers its deletion as a teardown block of
    /// `testCase` (`SandboxUserCleanup.delete`: the user signs in, answering the pool's MFA from the code
    /// API or an enrolled TOTP secret, and deletes itself). Registered at sign-up, not once the test holds
    /// tokens, so a user the test never signs in to completion (an MFA challenge it only observes, a
    /// sign-in it never makes, a failed assertion) is deleted too. The pool's code subscription is started
    /// first, so the codes this user is sent are seen.
    func signUp(
        _ user: TestUser,
        email: String,
        phoneNumber: String? = nil,
        deletingAtTeardownOf testCase: XCTestCase
    ) async throws -> SignUpOutput {
        var attributes = [CognitoIdentityProviderClientTypes.AttributeType(name: "email", value: email)]
        if let phoneNumber {
            attributes.append(CognitoIdentityProviderClientTypes.AttributeType(name: "phone_number", value: phoneNumber))
        }
        // Before any request: a role that cannot confirm a user gets no sign-up, so no message either.
        try SandboxSignUp.requireNotKnownUnconfirmable(kind)
        await CodeSink.prepare(kind)
        let signedUpAt = Date()
        let output = try await client.signUp(input: SignUpInput(
            clientId: clientId,
            password: user.password,
            userAttributes: attributes,
            username: user.username
        ))
        if let userSub = output.userSub {
            let fresh = FreshUser(
                pool: kind,
                username: user.username,
                password: user.password,
                email: email,
                phoneNumber: phoneNumber,
                userSub: userSub,
                isConfirmed: output.userConfirmed,
                signedUpAt: signedUpAt
            )
            testCase.deleteAtTeardown(fresh)
            // A pool with no pre-sign-up trigger (the plugin's passwordless backend) leaves every sign-up
            // unconfirmed: confirm a user the test did not ask to leave unconfirmed, as `SandboxSignUp` does.
            // The returned output is Cognito's, so a test checking the trigger still sees what it did.
            if !output.userConfirmed, !user.username.hasPrefix(SandboxSignUp.confirmPrefix) {
                try SandboxSignUp.requireCodeAPIToConfirm(kind)
                try await SandboxSignUp.confirm(fresh, sentSince: signedUpAt, on: SandboxPools.pool(kind), sink: CodeSink())
            }
        }
        return output
    }

    func passwordSignIn(_ user: (username: String, password: String, email: String)) async throws -> RawSignInStep {
        try await passwordSignIn(TestUser(username: user.username, password: user.password))
    }

    /// A password sign-in: `USER_PASSWORD_AUTH`, or SRP where the app client offers no such flow (the
    /// plugin's MFA-required, email-MFA and device-alias backends), as `SandboxPoolClient.passwordSignIn`.
    func passwordSignIn(_ user: TestUser) async throws -> RawSignInStep {
        try await SandboxPools.pool(kind).passwordSignIn(user)
    }

    /// If `result` carries an access token, registers the user's self-deletion with it as a teardown
    /// block. Teardown blocks run last-registered first, so this runs before the sign-up's cleanup, which
    /// then finds the user gone (one refused sign-in) instead of answering the pool's MFA again. Either
    /// may find the other already did the work: a user already gone is not an error (seen once in a full
    /// run: `UserNotFoundException` from this `DeleteUser`, the user already deleted).
    func deleteAtTeardown(_ result: CognitoIdentityProviderClientTypes.AuthenticationResultType?, of testCase: XCTestCase) {
        guard let accessToken = result?.accessToken else {
            return
        }
        let client = client
        testCase.addTeardownBlock {
            do {
                _ = try await client.deleteUser(input: DeleteUserInput(accessToken: accessToken))
            } catch is AWSCognitoIdentityProvider.UserNotFoundException {
                // Already deleted.
            } catch is AWSCognitoIdentityProvider.NotAuthorizedException {
                // The token no longer works: the user was deleted, which revokes it.
            }
        }
    }
}
