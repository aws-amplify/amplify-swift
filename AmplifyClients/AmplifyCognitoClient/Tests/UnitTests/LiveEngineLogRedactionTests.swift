//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
@testable import AmplifyFoundation
import AWSCognitoIdentityProvider
import Foundation
import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The live engine's own log lines, as the client's log sink receives them, over scripted Cognito: no form of the
/// username reaches the sink, including the ones a sign-in event carries without a label.
final class LiveEngineLogRedactionTests: XCTestCase {

    /// The name the user types: an email alias.
    private static let typed = "log.probe@example.com"
    /// Cognito's username for the user, which it echoes in its challenges.
    private static let cognitoName = "log-probe-cognito-name"

    /// The rest of a sent `initiateTOTPSetup` line: the challenge, with Cognito's username and the typed one redacted.
    private static let totpChallenge = "InternalAWSCognitoAuth.RespondToAuthChallenge(challenge: "
        + "AWSCognitoIdentityProvider.CognitoIdentityProviderClientTypes.ChallengeNameType.mfaSetup, "
        + #"availableChallenges: [], username: "<redacted>", session: Optional("<REDACTED>"), "#
        + #"parameters: Optional(["MFAS_CAN_SETUP": "[\"SOFTWARE_TOKEN_MFA\"]"]), inputUsername: Optional("<redacted>"))), "#
        + "time: nil)"

    private var harness: LiveEngineHarness!
    private var sink: CategoryCapture!

    override func setUp() {
        super.setUp()
        harness = LiveEngineHarness()
        sink = CategoryCapture()
        AmplifyLogging.addSink(sink)
    }

    override func tearDown() {
        AmplifyLogging.removeSink(sink)
        sink = nil
        harness.cognito.assertConsumed()
        harness = nil
        super.tearDown()
    }

    /// The lines the engine logged that send `event`, from `fileID`, each event's random ID replaced by `<id>`.
    private func lines(sending event: String, from fileID: String) -> [String] {
        sink.allLines()
            .filter { $0.hasPrefix("InternalAWSCognitoAuth/\(fileID) Sending event ") && $0.contains(".\(event)(") }
            .map { $0.replacingOccurrences(of: #"id: "[0-9A-F-]{36}""#, with: #"id: "<id>""#, options: .regularExpression) }
    }

    /// Fails for every line that holds either username, in clear or as the engine masks it.
    private func assertNoUsername(file: StaticString = #filePath, line: UInt = #line) {
        let forms = [Self.typed, Self.cognitoName, Self.typed.maskedForLog(), Self.cognitoName.maskedForLog()]
        for logged in sink.allLines() {
            for form in forms where logged.contains(form) {
                XCTFail("a line holds \(form): \(logged)", file: file, line: line)
            }
        }
    }

    /// Test that a sign-in that uses this device's record logs its device SRP event without the typed username
    ///
    /// - Given: a device record under the typed email alias, and SRP answered with `DEVICE_SRP_AUTH`, then
    ///   `DEVICE_PASSWORD_VERIFIER`, then tokens
    /// - When:
    ///    - the user signs in with the alias
    /// - Then:
    ///    - the engine's line sending `initiateDeviceSRP` is its own, with the username `<redacted>`
    ///    - no line the sink receives holds the alias or Cognito's username, in clear or masked
    ///
    func testTheDeviceSRPEventReachesTheSinkWithoutTheUsername() async throws {
        let deviceKey = "us-east-1_device-probe"
        let metadata = DeviceMetadata.metadata(.init(deviceKey: deviceKey, deviceGroupKey: "group-probe"))
        try harness.keychain.deviceStore(for: harness.namespace).saveDeviceMetadata(metadata, for: Self.typed)
        let engine = try harness.engine()
        let verifier = LiveEngineFixtures.passwordVerifier(Self.cognitoName)
        harness.cognito.once("InitiateAuth") { (_: InitiateAuthInput) in verifier }
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in
            LiveEngineFixtures.challenge(.deviceSrpAuth, session: "device-srp-session")
        }
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in
            LiveEngineFixtures.challenge(
                .devicePasswordVerifier,
                parameters: verifier.challengeParameters ?? [:],
                session: "device-verifier-session"
            )
        }
        harness.cognito.once("RespondToAuthChallenge") { (_: RespondToAuthChallengeInput) in
            LiveEngineFixtures.signedIn(Self.cognitoName)
        }
        harness.scriptIdentityPool()

        guard case .done = try await engine.signIn(.srp(Self.typed), current: nil) else {
            return XCTFail("the sign-in did not finish")
        }

        let answers = harness.cognito.inputs("RespondToAuthChallenge", as: RespondToAuthChallengeInput.self)
        XCTAssertEqual(answers.map(\.challengeName), [.passwordVerifier, .deviceSrpAuth, .devicePasswordVerifier])
        let sent = lines(sending: "initiateDeviceSRP", from: "VerifyPasswordSRP.swift")
        XCTAssertEqual(sent, [
            #"InternalAWSCognitoAuth/VerifyPasswordSRP.swift Sending event SignInEvent(data: nil, id: "<id>", "#
                + #"eventType: InternalAWSCognitoAuth.SignInEvent.EventType.initiateDeviceSRP("<redacted>", "#
                + #"RespondToAuthChallengeOutput(ChallengeName: "DEVICE_SRP_AUTH", ChallengeParameters: [:], "#
                + "Session: [CONTENT_REDACTED])), time: nil)"
        ])
        assertNoUsername()
    }

    /// Test that a TOTP setup that a sign-in goes straight into logs its event without the username
    ///
    /// - Given: SRP answered with `MFA_SETUP` for TOTP only, and `AssociateSoftwareToken` answering a secret
    /// - When:
    ///    - the user signs in with the alias
    /// - Then:
    ///    - the sign-in stops on `.continueSignInWithTOTPSetup`
    ///    - the engine's line sending `initiateTOTPSetup` is its own, with both usernames `<redacted>`
    ///    - no line the sink receives holds the alias or Cognito's username, in clear or masked
    ///
    func testTheTOTPSetupEventReachesTheSinkWithoutTheUsername() async throws {
        let engine = try harness.engine()
        harness.scriptSRP(
            Self.cognitoName,
            then: LiveEngineFixtures.challenge(.mfaSetup, parameters: ["MFAS_CAN_SETUP": #"["SOFTWARE_TOKEN_MFA"]"#])
        )
        harness.cognito.once("AssociateSoftwareToken") { (_: AssociateSoftwareTokenInput) in
            AssociateSoftwareTokenOutput(secretCode: "SHARED-SECRET", session: "setup-session")
        }

        let first = try await engine.signIn(.srp(Self.typed), current: nil)

        guard case .challenge(.continueSignInWithTOTPSetup) = first else {
            return XCTFail("expected a TOTP setup, got \(first)")
        }
        let sent = lines(sending: "initiateTOTPSetup", from: "VerifyPasswordSRP.swift")
        XCTAssertEqual(sent, [
            #"InternalAWSCognitoAuth/VerifyPasswordSRP.swift Sending event SignInEvent(data: nil, id: "<id>", "#
                + #"eventType: InternalAWSCognitoAuth.SignInEvent.EventType.initiateTOTPSetup("<redacted>", "#
                + Self.totpChallenge
        ])
        assertNoUsername()
    }

    /// Test that a TOTP setup chosen at an MFA setup selection logs its event without the username
    ///
    /// - Given: SRP answered with `MFA_SETUP` for TOTP or email, and `AssociateSoftwareToken` answering a secret
    /// - When:
    ///    - the user signs in with the alias, then chooses TOTP
    /// - Then:
    ///    - the choice gives `.continueSignInWithTOTPSetup`
    ///    - the engine's line sending `initiateTOTPSetup` is its own, with both usernames `<redacted>`
    ///    - no line the sink receives holds the alias or Cognito's username, in clear or masked
    ///
    func testTheTOTPSetupEventOfAnMFASetupSelectionReachesTheSinkWithoutTheUsername() async throws {
        let engine = try harness.engine()
        harness.scriptSRP(
            Self.cognitoName,
            then: LiveEngineFixtures.challenge(
                .mfaSetup,
                parameters: ["MFAS_CAN_SETUP": #"["SOFTWARE_TOKEN_MFA","EMAIL_OTP"]"#]
            )
        )
        harness.cognito.once("AssociateSoftwareToken") { (_: AssociateSoftwareTokenInput) in
            AssociateSoftwareTokenOutput(secretCode: "SHARED-SECRET", session: "setup-session")
        }

        let first = try await engine.signIn(.srp(Self.typed), current: nil)
        guard case .challenge(.continueSignInWithMFASetupSelection) = first else {
            return XCTFail("expected an MFA setup selection, got \(first)")
        }
        let chosen = try await engine.confirmSignIn(.answer("SOFTWARE_TOKEN_MFA"), current: nil)

        guard case .challenge(.continueSignInWithTOTPSetup) = chosen else {
            return XCTFail("expected a TOTP setup, got \(chosen)")
        }
        let sent = lines(sending: "initiateTOTPSetup", from: "VerifySignInChallenge.swift")
        XCTAssertEqual(sent, [
            #"InternalAWSCognitoAuth/VerifySignInChallenge.swift Sending event SignInEvent(data: nil, id: "<id>", "#
                + #"eventType: InternalAWSCognitoAuth.SignInEvent.EventType.initiateTOTPSetup("<redacted>", "#
                + Self.totpChallenge
        ])
        assertNoUsername()
    }
}
