//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation
import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// TOTP setup and MFA preferences over the live engine and scripted Cognito: `setUpTOTP`, `verifyTOTPSetup`,
/// `fetchMFAPreference` and `updateMFAPreference`, ported from the plugin's `SetUpTOTPTask`,
/// `VerifyTOTPSetupTask`, `FetchMFAPreferenceTask` and `UpdateMFAPreferenceTask`.
final class LiveEngineMFATests: XCTestCase {

    private var harness: LiveEngineHarness!

    override func setUp() {
        super.setUp()
        harness = LiveEngineHarness()
    }

    override func tearDown() {
        harness.cognito.assertConsumed()
        harness = nil
        super.tearDown()
    }

    private var aliceAccessToken: String {
        LiveEngineFixtures.jwt("alice", use: "access")
    }

    /// Signs alice in, then forgets the calls it took, so each test sees only its own.
    private func signedIn(on engine: LiveSessionEngine) async throws -> Data {
        let payload = try await harness.signedInPayload(on: engine)
        harness = harness.resettingCalls()
        return payload
    }

    private func scriptGetUser(settings: [String]?, preferred: String?) {
        harness.cognito.always("GetUser") { (_: GetUserInput) in
            GetUserOutput(
                mfaOptions: nil,
                preferredMfaSetting: preferred,
                userAttributes: [],
                userMFASettingList: settings,
                username: "alice"
            )
        }
    }

    // MARK: setUpTOTP

    /// - Given: alice's signed-in payload, and `AssociateSoftwareToken` answering a secret
    /// - When:
    ///    - `setUpTOTP` is called
    /// - Then:
    ///    - the one call is `AssociateSoftwareToken` with her access token, and no session
    ///    - the details carry the secret and her username
    ///
    func testSetUpTOTPAssociatesWithThePayloadsAccessToken() async throws {
        let engine = try harness.engine()
        let payload = try await signedIn(on: engine)
        harness.cognito.once("AssociateSoftwareToken") { (_: AssociateSoftwareTokenInput) in
            AssociateSoftwareTokenOutput(secretCode: "FIXTURESECRET", session: nil)
        }

        let details = try await engine.setUpTOTP(payload)

        XCTAssertEqual(harness.cognito.operations, ["AssociateSoftwareToken"])
        let input = try XCTUnwrap(harness.cognito.inputs("AssociateSoftwareToken", as: AssociateSoftwareTokenInput.self).first)
        XCTAssertEqual(input.accessToken, aliceAccessToken)
        XCTAssertNil(input.session)
        XCTAssertEqual(details.sharedSecret, "FIXTURESECRET")
        XCTAssertEqual(details.username, "alice")
    }

    /// - Given: `AssociateSoftwareToken` answering no secret
    /// - When:
    ///    - `setUpTOTP` is called
    /// - Then:
    ///    - it throws the plugin's `.service(nil, "Secret code cannot be retrieved", "")`
    ///
    func testSetUpTOTPWithoutASecretFails() async throws {
        let engine = try harness.engine()
        let payload = try await signedIn(on: engine)
        harness.cognito.once("AssociateSoftwareToken") { (_: AssociateSoftwareTokenInput) in
            AssociateSoftwareTokenOutput(secretCode: nil, session: nil)
        }

        await assertThrowsAsync({ try await engine.setUpTOTP(payload) }) { error in
            guard case .service(nil, let description, let suggestion, _) = authError(error) else {
                return XCTFail("expected .service(nil, …), got \(error)")
            }
            XCTAssertEqual(description, "Secret code cannot be retrieved")
            XCTAssertEqual(suggestion, "")
        }
        XCTAssertEqual(harness.cognito.operations, ["AssociateSoftwareToken"])
    }

    /// - Given: `AssociateSoftwareToken` failing with Cognito exceptions
    /// - When:
    ///    - `setUpTOTP` is called
    /// - Then:
    ///    - each is mapped as the plugin maps it: `NotAuthorizedException` → `.notAuthorized`,
    ///      `SoftwareTokenMFANotFoundException` → `.service(.softwareTokenMFANotEnabled)`
    ///
    func testSetUpTOTPMapsCognitoErrors() async throws {
        let engine = try harness.engine()
        let payload = try await signedIn(on: engine)
        harness.cognito.once("AssociateSoftwareToken") { (_: AssociateSoftwareTokenInput) -> AssociateSoftwareTokenOutput in
            throw AWSCognitoIdentityProvider.NotAuthorizedException(message: "Access Token has been revoked")
        }
        harness.cognito.once("AssociateSoftwareToken") { (_: AssociateSoftwareTokenInput) -> AssociateSoftwareTokenOutput in
            throw SoftwareTokenMFANotFoundException(message: "Software token MFA not found")
        }

        await assertThrowsAsync({ try await engine.setUpTOTP(payload) }) { error in
            guard case .notAuthorized(let description, _, _) = authError(error) else {
                return XCTFail("expected .notAuthorized, got \(error)")
            }
            XCTAssertEqual(description, "Access Token has been revoked")
        }
        await assertThrowsAsync({ try await engine.setUpTOTP(payload) }) { error in
            guard case .service(.softwareTokenMFANotEnabled?, _, _, _) = authError(error) else {
                return XCTFail("expected .service(.softwareTokenMFANotEnabled), got \(error)")
            }
        }
        XCTAssertEqual(harness.cognito.operations, ["AssociateSoftwareToken", "AssociateSoftwareToken"])
    }

    // MARK: verifyTOTPSetup

    /// - Given: alice's signed-in payload, and `VerifySoftwareToken` answering `SUCCESS`
    /// - When:
    ///    - the setup is verified with a code and a device name, then with no device name
    /// - Then:
    ///    - each call is `VerifySoftwareToken` with her access token, the code and the name as given
    ///
    func testVerifyTOTPSetupSendsTheCodeAndTheDeviceName() async throws {
        let engine = try harness.engine()
        let payload = try await signedIn(on: engine)
        harness.cognito.always("VerifySoftwareToken") { (_: VerifySoftwareTokenInput) in
            VerifySoftwareTokenOutput(session: nil, status: .success)
        }

        try await engine.verifyTOTPSetup(payload, code: "123456", friendlyDeviceName: "Phone")
        try await engine.verifyTOTPSetup(payload, code: "654321", friendlyDeviceName: nil)

        XCTAssertEqual(harness.cognito.operations, ["VerifySoftwareToken", "VerifySoftwareToken"])
        let inputs = harness.cognito.inputs("VerifySoftwareToken", as: VerifySoftwareTokenInput.self)
        XCTAssertEqual(inputs.map(\.accessToken), [aliceAccessToken, aliceAccessToken])
        XCTAssertEqual(inputs.map(\.userCode), ["123456", "654321"])
        XCTAssertEqual(inputs.map(\.friendlyDeviceName), ["Phone", nil])
        XCTAssertEqual(inputs.map(\.session), [nil, nil])
    }

    /// A wrong code: Cognito's `EnableSoftwareTokenMFAException`, which the plugin's MF-2 expects as
    /// `softwareTokenMFANotEnabled`.
    ///
    /// - Given: `VerifySoftwareToken` failing with `EnableSoftwareTokenMFAException`, then succeeding
    /// - When:
    ///    - the setup is verified twice
    /// - Then:
    ///    - the first throws `.service(.softwareTokenMFANotEnabled, …)`, the second returns
    ///
    func testAWrongCodeIsSoftwareTokenMFANotEnabledAndCanBeRetried() async throws {
        let engine = try harness.engine()
        let payload = try await signedIn(on: engine)
        harness.cognito.once("VerifySoftwareToken") { (_: VerifySoftwareTokenInput) -> VerifySoftwareTokenOutput in
            throw EnableSoftwareTokenMFAException(message: "Code mismatch")
        }
        harness.cognito.once("VerifySoftwareToken") { (_: VerifySoftwareTokenInput) in
            VerifySoftwareTokenOutput(session: nil, status: .success)
        }

        await assertThrowsAsync({ try await engine.verifyTOTPSetup(payload, code: "000000", friendlyDeviceName: nil) }) { error in
            guard case .service(.softwareTokenMFANotEnabled?, _, _, _) = authError(error) else {
                return XCTFail("expected .service(.softwareTokenMFANotEnabled), got \(error)")
            }
        }
        try await engine.verifyTOTPSetup(payload, code: "123456", friendlyDeviceName: nil)
        XCTAssertEqual(harness.cognito.operations, ["VerifySoftwareToken", "VerifySoftwareToken"])
    }

    /// The other exceptions `VerifySoftwareToken` can answer, mapped as the plugin maps them.
    ///
    /// - Given: `VerifySoftwareToken` failing with `CodeMismatchException`, `LimitExceededException` and
    ///   `TooManyRequestsException`
    /// - When:
    ///    - the setup is verified for each
    /// - Then:
    ///    - they are `.service(.codeMismatch)`, `.service(.limitExceeded)` and
    ///      `.service(.requestLimitExceeded)`, each with Cognito's message
    ///
    func testVerifyTOTPSetupMapsCognitoErrors() async throws {
        let engine = try harness.engine()
        let payload = try await signedIn(on: engine)
        let cases: [(any Error & Sendable, AuthClientServiceErrorCode)] = [
            (CodeMismatchException(message: "Invalid code received for user"), .codeMismatch),
            (LimitExceededException(message: "Attempt limit exceeded"), .limitExceeded),
            (AWSCognitoIdentityProvider.TooManyRequestsException(message: "Rate exceeded"), .requestLimitExceeded)
        ]
        for (thrown, _) in cases {
            harness.cognito.once("VerifySoftwareToken") { (_: VerifySoftwareTokenInput) -> VerifySoftwareTokenOutput in
                throw thrown
            }
        }

        for (thrown, expected) in cases {
            await assertThrowsAsync({ try await engine.verifyTOTPSetup(payload, code: "123456", friendlyDeviceName: nil) }) { error in
                guard case .service(let code?, let description, _, _) = authError(error) else {
                    return XCTFail("\(type(of: thrown)): expected .service, got \(error)")
                }
                XCTAssertEqual(code, expected, "\(type(of: thrown))")
                XCTAssertEqual(description, (thrown as? EngineAuthErrorConvertible)?.engineError.errorDescription)
            }
        }
        XCTAssertEqual(harness.cognito.operations, Array(repeating: "VerifySoftwareToken", count: cases.count))
    }

    /// The statuses other than `SUCCESS`, with the plugin's strings.
    ///
    /// - Given: `VerifySoftwareToken` answering no status, `ERROR`, and a status the SDK does not know
    /// - When:
    ///    - the setup is verified for each
    /// - Then:
    ///    - each throws `.service(nil, …)`: "Verify TOTP Result cannot be retrieved", "Unknown service
    ///      error occurred", and the unknown status's raw value
    ///    - the suggestions are the plugin's: "This should not happen. …" for no status, and the
    ///      report-a-bug text for the others, each naming the engine's function
    ///
    func testVerifyTOTPSetupStatusesOtherThanSuccessFail() async throws {
        let engine = try harness.engine()
        let payload = try await signedIn(on: engine)
        let reportBug = "There is a possibility that there is a bug if this error persists."
        let cases: [(CognitoIdentityProviderClientTypes.VerifySoftwareTokenResponseType?, String, String)] = [
            (nil, "Verify TOTP Result cannot be retrieved", "This should not happen. \(reportBug)"),
            (.error, "Unknown service error occurred", reportBug),
            (.sdkUnknown("PENDING"), "PENDING", reportBug)
        ]
        for (status, _, _) in cases {
            harness.cognito.once("VerifySoftwareToken") { (_: VerifySoftwareTokenInput) in
                VerifySoftwareTokenOutput(session: nil, status: status)
            }
        }

        for (status, expected, suggestionPrefix) in cases {
            await assertThrowsAsync({ try await engine.verifyTOTPSetup(payload, code: "123456", friendlyDeviceName: nil) }) { error in
                guard case .service(nil, let description, let suggestion, _) = authError(error) else {
                    return XCTFail("\(String(describing: status)): expected .service(nil, …), got \(error)")
                }
                XCTAssertEqual(description, expected)
                XCTAssertTrue(suggestion.hasPrefix(suggestionPrefix), "\(String(describing: status)): \(suggestion)")
                XCTAssertTrue(suggestion.contains("function: verifyTOTPSetup"), "\(String(describing: status)): \(suggestion)")
            }
        }
        XCTAssertEqual(harness.cognito.operations, Array(repeating: "VerifySoftwareToken", count: cases.count))
    }

    // MARK: fetchMFAPreference

    /// - Given: `GetUser` answering several MFA settings
    /// - When:
    ///    - the preference is fetched for each
    /// - Then:
    ///    - `enabled` is `nil` when no type is on, else the types on (Cognito's names, any case); names
    ///      that are no MFA type are skipped; `preferred` is the preferred type, if any
    ///    - the one call is `GetUser` with her access token
    ///
    func testFetchMFAPreferenceReadsGetUser() async throws {
        let engine = try harness.engine()
        let payload = try await signedIn(on: engine)
        let cases: [([String]?, String?, AuthClientUserMFAPreference)] = [
            (nil, nil, AuthClientUserMFAPreference(enabled: nil, preferred: nil)),
            ([], nil, AuthClientUserMFAPreference(enabled: nil, preferred: nil)),
            (["SOFTWARE_TOKEN_MFA"], nil, AuthClientUserMFAPreference(enabled: [.totp], preferred: nil)),
            (["SMS_MFA", "SOFTWARE_TOKEN_MFA"], "SOFTWARE_TOKEN_MFA", AuthClientUserMFAPreference(enabled: [.sms, .totp], preferred: .totp)),
            (["sms_mfa", "EMAIL_OTP"], "EMAIL_OTP", AuthClientUserMFAPreference(enabled: [.sms, .email], preferred: .email)),
            (["WEB_AUTHN"], "WEB_AUTHN", AuthClientUserMFAPreference(enabled: nil, preferred: nil)),
            (["WEB_AUTHN", "SMS_MFA"], "SMS_MFA", AuthClientUserMFAPreference(enabled: [.sms], preferred: .sms))
        ]

        for (settings, preferred, expected) in cases {
            harness.cognito.once("GetUser") { (_: GetUserInput) in
                GetUserOutput(preferredMfaSetting: preferred, userAttributes: [], userMFASettingList: settings, username: "alice")
            }
            let preference = try await engine.fetchMFAPreference(payload)
            XCTAssertEqual(preference, expected, "\(String(describing: settings)), \(String(describing: preferred))")
        }
        XCTAssertEqual(harness.cognito.operations, Array(repeating: "GetUser", count: cases.count))
        XCTAssertEqual(
            Set(harness.cognito.inputs("GetUser", as: GetUserInput.self).map(\.accessToken)),
            [aliceAccessToken]
        )
    }

    // MARK: updateMFAPreference

    /// - Given: alice's payload, with TOTP preferred
    /// - When:
    ///    - the preference is updated with SMS `.enabled`, TOTP `.enabled` and no email
    /// - Then:
    ///    - `GetUser`, then one `SetUserMFAPreference` with her access token: SMS `(true, false)`, TOTP
    ///      `(true, true)` (it stays preferred), and no email setting
    ///
    func testUpdateMFAPreferenceReadsThePreferredTypeFirst() async throws {
        let engine = try harness.engine()
        let payload = try await signedIn(on: engine)
        scriptGetUser(settings: ["SOFTWARE_TOKEN_MFA"], preferred: "SOFTWARE_TOKEN_MFA")
        harness.cognito.once("SetUserMFAPreference") { (_: SetUserMFAPreferenceInput) in SetUserMFAPreferenceOutput() }

        try await engine.updateMFAPreference(payload, sms: .enabled, totp: .enabled, email: nil)

        XCTAssertEqual(harness.cognito.operations, ["GetUser", "SetUserMFAPreference"])
        XCTAssertEqual(harness.cognito.inputs("GetUser", as: GetUserInput.self).first?.accessToken, aliceAccessToken)
        let input = try XCTUnwrap(harness.cognito.inputs("SetUserMFAPreference", as: SetUserMFAPreferenceInput.self).first)
        XCTAssertEqual(input.accessToken, aliceAccessToken)
        XCTAssertEqual(input.smsMfaSettings?.enabled, true)
        XCTAssertEqual(input.smsMfaSettings?.preferredMfa, false)
        XCTAssertEqual(input.softwareTokenMfaSettings?.enabled, true)
        XCTAssertEqual(input.softwareTokenMfaSettings?.preferredMfa, true)
        XCTAssertNil(input.emailMfaSettings)
    }

    /// Every preference for every type, against every current preferred type, as the plugin's
    /// `MFAPreference` extension builds the settings.
    ///
    /// - Given: `GetUser` answering each preferred type in turn (none, SMS, TOTP, email)
    /// - When:
    ///    - the preference is updated with the same value for all three types, for each value
    /// - Then:
    ///    - `.enabled` is `(true, isCurrentlyPreferred)`, `.preferred` `(true, true)`, `.notPreferred`
    ///      `(true, false)`, `.disabled` `(false, false)`
    ///
    func testUpdateMFAPreferenceBuildsThePluginsSettings() async throws {
        let engine = try harness.engine()
        let payload = try await signedIn(on: engine)
        harness.cognito.always("SetUserMFAPreference") { (_: SetUserMFAPreferenceInput) in SetUserMFAPreferenceOutput() }
        let preferences: [AuthClientMFAPreference] = [.enabled, .preferred, .notPreferred, .disabled]

        for current in [nil, "SMS_MFA", "SOFTWARE_TOKEN_MFA", "EMAIL_OTP"] {
            for preference in preferences {
                harness.cognito.once("GetUser") { (_: GetUserInput) in
                    GetUserOutput(preferredMfaSetting: current, userAttributes: [], username: "alice")
                }
                harness.cognito.clearCalls()

                try await engine.updateMFAPreference(payload, sms: preference, totp: preference, email: preference)

                XCTAssertEqual(harness.cognito.operations, ["GetUser", "SetUserMFAPreference"], "\(preference), \(current ?? "none")")
                let input = try XCTUnwrap(harness.cognito.inputs("SetUserMFAPreference", as: SetUserMFAPreferenceInput.self).last)
                func expected(_ type: String) -> (Bool, Bool) {
                    switch preference {
                    case .enabled: return (true, current == type)
                    case .preferred: return (true, true)
                    case .notPreferred: return (true, false)
                    case .disabled: return (false, false)
                    }
                }
                let context = "\(preference) with \(current ?? "none") preferred"
                XCTAssertEqual(input.smsMfaSettings?.enabled, expected("SMS_MFA").0, context)
                XCTAssertEqual(input.smsMfaSettings?.preferredMfa, expected("SMS_MFA").1, context)
                XCTAssertEqual(input.softwareTokenMfaSettings?.enabled, expected("SOFTWARE_TOKEN_MFA").0, context)
                XCTAssertEqual(input.softwareTokenMfaSettings?.preferredMfa, expected("SOFTWARE_TOKEN_MFA").1, context)
                XCTAssertEqual(input.emailMfaSettings?.enabled, expected("EMAIL_OTP").0, context)
                XCTAssertEqual(input.emailMfaSettings?.preferredMfa, expected("EMAIL_OTP").1, context)
            }
        }
    }

    /// As the plugin: no type given still reads `GetUser` and sends a `SetUserMFAPreference` with no
    /// settings.
    ///
    /// - Given: alice's payload
    /// - When:
    ///    - the preference is updated with every type `nil`
    /// - Then:
    ///    - `GetUser`, then `SetUserMFAPreference` with only her access token
    ///
    func testUpdateMFAPreferenceWithNoTypeSendsNoSettings() async throws {
        let engine = try harness.engine()
        let payload = try await signedIn(on: engine)
        scriptGetUser(settings: nil, preferred: nil)
        harness.cognito.once("SetUserMFAPreference") { (_: SetUserMFAPreferenceInput) in SetUserMFAPreferenceOutput() }

        try await engine.updateMFAPreference(payload, sms: nil, totp: nil, email: nil)

        XCTAssertEqual(harness.cognito.operations, ["GetUser", "SetUserMFAPreference"])
        let input = try XCTUnwrap(harness.cognito.inputs("SetUserMFAPreference", as: SetUserMFAPreferenceInput.self).first)
        XCTAssertNil(input.smsMfaSettings)
        XCTAssertNil(input.softwareTokenMfaSettings)
        XCTAssertNil(input.emailMfaSettings)
    }

    /// Two preferred types: Cognito's `InvalidParameterException` (MF-11), and a failed `GetUser` stops
    /// before the update.
    ///
    /// - Given: `SetUserMFAPreference` failing with `InvalidParameterException`; then `GetUser` failing
    /// - When:
    ///    - the preference is updated twice
    /// - Then:
    ///    - the first throws `.service(.invalidParameter, …)`; the second `.service(.userNotFound, …)`,
    ///      with no second `SetUserMFAPreference`
    ///
    func testUpdateMFAPreferenceMapsCognitoErrors() async throws {
        let engine = try harness.engine()
        let payload = try await signedIn(on: engine)
        harness.cognito.once("GetUser") { (_: GetUserInput) in GetUserOutput(userAttributes: [], username: "alice") }
        harness.cognito.once("SetUserMFAPreference") { (_: SetUserMFAPreferenceInput) -> SetUserMFAPreferenceOutput in
            throw InvalidParameterException(message: "Only one MFA method can be preferred")
        }
        harness.cognito.once("GetUser") { (_: GetUserInput) -> GetUserOutput in
            throw UserNotFoundException(message: "User does not exist.")
        }

        await assertThrowsAsync({ try await engine.updateMFAPreference(payload, sms: .preferred, totp: .preferred, email: nil) }) { error in
            guard case .service(.invalidParameter?, _, _, _) = authError(error) else {
                return XCTFail("expected .service(.invalidParameter), got \(error)")
            }
        }
        await assertThrowsAsync({ try await engine.updateMFAPreference(payload, sms: .preferred, totp: nil, email: nil) }) { error in
            guard case .service(.userNotFound?, _, _, _) = authError(error) else {
                return XCTFail("expected .service(.userNotFound), got \(error)")
            }
        }
        XCTAssertEqual(harness.cognito.operations, ["GetUser", "SetUserMFAPreference", "GetUser"])
    }

    // MARK: Every operation

    /// A payload with no user pool user is refused before Cognito, should one reach the engine.
    ///
    /// - Given: a guest payload
    /// - When:
    ///    - each MFA operation is called
    /// - Then:
    ///    - each throws `SessionEngineError.notSignedIn`, and no user pool call is made
    ///
    func testAPayloadWithoutAUserIsRefused() async throws {
        let engine = try harness.engine()
        harness.scriptIdentityPool()
        let guest = try await engine.fetchGuestCredentials(current: nil)
        harness.cognito.clearCalls()
        let calls: [(String, () async throws -> Any)] = [
            ("setUpTOTP", { try await engine.setUpTOTP(guest) }),
            ("verifyTOTPSetup", { try await engine.verifyTOTPSetup(guest, code: "123456", friendlyDeviceName: nil) }),
            ("fetchMFAPreference", { try await engine.fetchMFAPreference(guest) }),
            ("updateMFAPreference", { try await engine.updateMFAPreference(guest, sms: .enabled, totp: nil, email: nil) })
        ]

        for (name, call) in calls {
            await assertThrowsAsync({ try await call() }) { error in
                guard case SessionEngineError.notSignedIn = error else {
                    return XCTFail("\(name): expected notSignedIn, got \(error)")
                }
            }
        }
        XCTAssertEqual(harness.cognito.operations, [])
    }

    /// The MFA operations touch none of the actor's state: a sign-in waiting on a challenge stays pending.
    ///
    /// - Given: alice's payload, then a second sign-in on the same engine stopped on `SMS_MFA`
    /// - When:
    ///    - each MFA operation runs with alice's payload
    /// - Then:
    ///    - each succeeds, and the challenge is still pending afterwards
    ///
    func testTheOperationsLeaveAPendingSignInAlone() async throws {
        let engine = try harness.engine()
        let payload = try await signedIn(on: engine)
        harness.scriptSRP(then: LiveEngineFixtures.challenge(.smsMfa, parameters: LiveEngineFixtures.smsParameters))
        guard case .challenge = try await engine.signIn(.srp(), current: nil) else {
            return XCTFail("the scripted sign-in should stop on SMS_MFA")
        }
        harness.cognito.once("AssociateSoftwareToken") { (_: AssociateSoftwareTokenInput) in
            AssociateSoftwareTokenOutput(secretCode: "FIXTURESECRET", session: nil)
        }
        harness.cognito.once("VerifySoftwareToken") { (_: VerifySoftwareTokenInput) in
            VerifySoftwareTokenOutput(session: nil, status: .success)
        }
        scriptGetUser(settings: ["SOFTWARE_TOKEN_MFA"], preferred: nil)
        harness.cognito.once("SetUserMFAPreference") { (_: SetUserMFAPreferenceInput) in SetUserMFAPreferenceOutput() }
        harness.cognito.clearCalls()

        _ = try await engine.setUpTOTP(payload)
        try await engine.verifyTOTPSetup(payload, code: "123456", friendlyDeviceName: nil)
        _ = try await engine.fetchMFAPreference(payload)
        try await engine.updateMFAPreference(payload, sms: nil, totp: .preferred, email: nil)

        XCTAssertEqual(harness.cognito.operations, [
            "AssociateSoftwareToken", "VerifySoftwareToken", "GetUser", "GetUser", "SetUserMFAPreference"
        ], "only the MFA calls: nothing answers or cancels the pending challenge")

        let pending = await engine.pendingChallenge
        guard case .confirmSignInWithSMSMFACode = pending else {
            return XCTFail("the SMS_MFA challenge should still be pending, got \(String(describing: pending))")
        }
    }

    // MARK: The public API over the live engine

    /// The public calls reach Cognito with the session's access token, and their errors come out as the
    /// engine mapped them.
    ///
    /// - Given: a client over the live engine and scripted Cognito, alice signed in
    /// - When:
    ///    - she sets up TOTP, verifies it with a wrong code and then a right one, prefers it, and fetches
    ///      her preference; then `GetUser` fails with an error Cognito's mapping does not know
    /// - Then:
    ///    - the setup has her secret and username; the wrong code is `.service(.softwareTokenMFANotEnabled)`
    ///    - every call carries her access token, and the fetch returns TOTP enabled and preferred
    ///    - the unknown failure is the core's `.unknown("The client could not fetch the MFA preference.")`
    ///    - the state stays `.signedIn(alice)`
    ///
    func testThePublicCallsOverTheLiveEngine() async throws {
        let clientHarness = ClientHarness()
        let base = clientHarness.dependencies
        let harness = harness!
        let dependencies = SessionCoreDependencies(
            registry: base.registry,
            gates: base.gates,
            makeStore: base.makeStore,
            makeClients: base.makeClients,
            makeEngine: { _ in try harness.engine() },
            makeRevoker: base.makeRevoker,
            scheduleRestore: base.scheduleRestore,
            bounds: base.bounds,
            now: { Date() }
        )
        let client = try AmplifyCognitoClient(
            configuration: ClientFixtures.configuration,
            options: .init(sessionId: ClientFixtures.id("work")),
            dependencies: dependencies
        )
        harness.scriptSRP()
        harness.scriptIdentityPool()
        _ = try await client.signIn(username: "alice", password: "password")
        harness.cognito.clearCalls()
        harness.cognito.once("AssociateSoftwareToken") { (_: AssociateSoftwareTokenInput) in
            AssociateSoftwareTokenOutput(secretCode: "FIXTURESECRET", session: nil)
        }
        harness.cognito.once("VerifySoftwareToken") { (_: VerifySoftwareTokenInput) -> VerifySoftwareTokenOutput in
            throw EnableSoftwareTokenMFAException(message: "Code mismatch")
        }
        harness.cognito.once("VerifySoftwareToken") { (_: VerifySoftwareTokenInput) in
            VerifySoftwareTokenOutput(session: nil, status: .success)
        }
        harness.cognito.once("GetUser") { (_: GetUserInput) in GetUserOutput(userAttributes: [], username: "alice") }
        harness.cognito.once("SetUserMFAPreference") { (_: SetUserMFAPreferenceInput) in SetUserMFAPreferenceOutput() }
        harness.cognito.once("GetUser") { (_: GetUserInput) in
            GetUserOutput(preferredMfaSetting: "SOFTWARE_TOKEN_MFA", userAttributes: [], userMFASettingList: ["SOFTWARE_TOKEN_MFA"], username: "alice")
        }
        harness.cognito.once("GetUser") { (_: GetUserInput) -> GetUserOutput in
            throw ScriptedCognitoError.notScripted("an error the engine does not map")
        }

        let details = try await client.setUpTOTP()
        await assertThrowsAsync({ try await client.verifyTOTPSetup(code: "000000") }) { error in
            guard case .service(.softwareTokenMFANotEnabled?, _, _, _) = authError(error) else {
                return XCTFail("expected .service(.softwareTokenMFANotEnabled), got \(error)")
            }
        }
        try await client.verifyTOTPSetup(code: "123456", options: .init(friendlyDeviceName: "Phone"))
        try await client.updateMFAPreference(totp: .preferred)
        let preference = try await client.fetchMFAPreference()
        await assertThrowsAsync({ try await client.fetchMFAPreference() }) { error in
            guard case .unknown(let description, _, _) = authError(error) else {
                return XCTFail("expected .unknown, got \(error)")
            }
            XCTAssertEqual(description, "The client could not fetch the MFA preference.")
        }

        XCTAssertEqual(details.sharedSecret, "FIXTURESECRET")
        XCTAssertEqual(details.username, "alice")
        XCTAssertEqual(preference, AuthClientUserMFAPreference(enabled: [.totp], preferred: .totp))
        XCTAssertEqual(harness.cognito.operations, [
            "AssociateSoftwareToken", "VerifySoftwareToken", "VerifySoftwareToken",
            "GetUser", "SetUserMFAPreference", "GetUser", "GetUser"
        ])
        let tokens = harness.cognito.calls.compactMap { call -> String? in
            switch call.input {
            case let input as AssociateSoftwareTokenInput: return input.accessToken
            case let input as VerifySoftwareTokenInput: return input.accessToken
            case let input as GetUserInput: return input.accessToken
            case let input as SetUserMFAPreferenceInput: return input.accessToken
            default: return nil
            }
        }
        XCTAssertEqual(tokens, Array(repeating: aliceAccessToken, count: 7))
        XCTAssertEqual(
            harness.cognito.inputs("VerifySoftwareToken", as: VerifySoftwareTokenInput.self).last?.friendlyDeviceName,
            "Phone"
        )
        let setting = harness.cognito.inputs("SetUserMFAPreference", as: SetUserMFAPreferenceInput.self).first
        XCTAssertEqual(setting?.softwareTokenMfaSettings?.preferredMfa, true)
        XCTAssertNil(setting?.smsMfaSettings)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")))
    }
}
