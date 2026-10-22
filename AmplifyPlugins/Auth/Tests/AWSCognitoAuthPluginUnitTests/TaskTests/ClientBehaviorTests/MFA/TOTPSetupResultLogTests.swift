//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation
import XCTest
@testable import Amplify
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// The plugin logs no TOTP shared secret: its tasks log their result at info ("Successfully completed execution
/// for … with result:"), and the results of `setUpTOTP` and of a `confirmSignIn` that starts a TOTP setup hold
/// `TOTPSetupDetails`, which prints its secret redacted.
final class TOTPSetupResultLogTests: BasePluginTest, @unchecked Sendable {

    private static let secret = "JBSWY3DPEHPK3PXPJBSWY3DPEHPK3PXP"

    private var capture: CapturingLoggingPlugin!
    private var savedPlugins: [PluginKey: LoggingCategoryPlugin] = [:]
    private var savedLogLevel: LogLevel = .error
    private var savedRouter: (any EngineLogRouter)?

    override func setUp() {
        super.setUp()
        capture = CapturingLoggingPlugin()
        savedPlugins = Amplify.Logging.plugins
        savedLogLevel = Amplify.Logging.logLevel
        savedRouter = EngineLog.router
        Amplify.Logging.plugins = [capture.key: capture]
        Amplify.Logging.logLevel = .verbose
        // The engine's sign-in helpers log through the global engine router.
        EngineLog.install(AmplifyEngineLogRouter())
    }

    override func tearDown() async throws {
        Amplify.Logging.plugins = savedPlugins
        Amplify.Logging.logLevel = savedLogLevel
        if let savedRouter {
            EngineLog.install(savedRouter)
        }
        try await super.tearDown()
    }

    /// Fails for every captured line that holds the secret, and unless the task's result line was logged with the
    /// secret redacted.
    private func assertNoLineHoldsTheSecret(
        resultLineFor eventName: HubPayloadEventName,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let lines = capture.lines
        for captured in lines where captured.message.contains(Self.secret) {
            XCTFail("a log line holds the secret: \(captured.level) \(captured.message)", file: file, line: line)
        }
        let resultLines = lines.filter {
            $0.message.hasPrefix("Successfully completed execution for \(eventName) with result:")
        }
        XCTAssertEqual(resultLines.count, 1, "the result line is logged once", file: file, line: line)
        XCTAssertEqual(resultLines.first?.level, "info", file: file, line: line)
        XCTAssertTrue(
            resultLines.first?.message.contains(#"sharedSecret: "<REDACTED>""#) == true,
            "the result line shows the secret redacted: \(resultLines.first?.message ?? "-")",
            file: file,
            line: line
        )
    }

    /// Test that `setUpTOTP` logs no line with the shared secret
    ///
    /// - Given: a signed-in plugin whose user pool answers `AssociateSoftwareToken` with a shared secret, and a
    ///   capturing logging plugin at verbose
    /// - When:
    ///    - I invoke setUpTOTP
    /// - Then:
    ///    - the result holds the secret in full
    ///    - no log line holds the secret, and the task's result line, at info, shows it `<REDACTED>`
    ///
    func testSetUpTOTPLogsNoLineWithTheSecret() async throws {
        mockIdentityProvider = MockIdentityProvider(
            mockAssociateSoftwareTokenResponse: { _ in
                .init(secretCode: Self.secret)
            })

        let details = try await plugin.setUpTOTP()

        XCTAssertEqual(details.sharedSecret, Self.secret)
        assertNoLineHoldsTheSecret(resultLineFor: HubPayload.EventName.Auth.setUpTOTPAPI)
    }

    /// Test that a `confirmSignIn` that starts a TOTP setup logs no line with the shared secret
    ///
    /// - Given: a signed-out plugin whose user pool answers sign-in with an MFA setup selection, and
    ///   `AssociateSoftwareToken` with a shared secret, and a capturing logging plugin at verbose
    /// - When:
    ///    - I sign in, then confirm sign-in by selecting TOTP
    /// - Then:
    ///    - the step is `.continueSignInWithTOTPSetup` with the secret in full
    ///    - no log line holds the secret, and the confirm sign-in task's result line, at info, shows it `<REDACTED>`
    ///
    func testConfirmSignInReachingTOTPSetupLogsNoLineWithTheSecret() async throws {
        let userPool = MockIdentityProvider(mockInitiateAuthResponse: { _ in
            InitiateAuthOutput(
                authenticationResult: .none,
                challengeName: .passwordVerifier,
                challengeParameters: InitiateAuthOutput.validChalengeParams,
                session: "someSession"
            )
        }, mockRespondToAuthChallengeResponse: { _ in
            .testData(
                challenge: .mfaSetup,
                challengeParameters: ["MFAS_CAN_SETUP": "[\"SMS_MFA\",\"SOFTWARE_TOKEN_MFA\",\"EMAIL_OTP\"]"]
            )
        }, mockAssociateSoftwareTokenResponse: { _ in
            .init(secretCode: Self.secret, session: "newSession")
        })
        let plugin = configureCustomPluginWith(
            userPool: { userPool },
            initialState: AuthState.configured(.signedOut(.init(lastKnownUserName: nil)), .configured, .notStarted)
        )

        let signInResult = try await plugin.signIn(
            username: "username",
            password: "password",
            options: AuthSignInRequest.Options()
        )
        guard case .continueSignInWithMFASetupSelection = signInResult.nextStep else {
            XCTFail("Result should be .continueSignInWithMFASetupSelection, instead got: \(signInResult.nextStep)")
            return
        }

        let result = try await plugin.confirmSignIn(challengeResponse: MFAType.totp.challengeResponse)

        guard case .continueSignInWithTOTPSetup(let details) = result.nextStep else {
            XCTFail("Result should be .continueSignInWithTOTPSetup, instead got: \(result.nextStep)")
            return
        }
        XCTAssertEqual(details.sharedSecret, Self.secret)
        assertNoLineHoldsTheSecret(resultLineFor: HubPayload.EventName.Auth.confirmSignInAPI)
    }
}
