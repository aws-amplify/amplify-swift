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

/// The plugin logs none of a sign-in's or sign-up's secrets, at any level: the user's answer to `confirmSignIn`,
/// the session `VerifySoftwareToken` returns while a TOTP setup finishes, and the auto sign-in session a sign-up
/// result carries. The answer and the TOTP session reach the verbose "Checking next step for:" and "Sending event"
/// lines inside the states and events that carry them; the sign-up session reaches the task's result line at info.
final class SignInSecretLogTests: BasePluginTest, @unchecked Sendable {

    private static let answer = "S3cret-4821"
    private static let totpSession = "totp-verify-session-value"
    private static let signUpSession = "auto-sign-in-session-value"

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

    /// Fails for every captured line that holds one of `secrets` in full, or one of `answers` in full or masked: a
    /// masked session keeps four characters of a long value, a masked code four of six digits.
    private func assertNoLineHolds(
        _ secrets: [String],
        answers: [String] = [],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let forbidden = secrets + answers + answers.map { $0.maskedForLog() }
        for captured in capture.lines {
            for secret in forbidden where captured.message.contains(secret) {
                XCTFail("a log line holds \(secret): \(captured.level) \(captured.message)", file: file, line: line)
            }
        }
    }

    /// The captured messages that start with `prefix`.
    private func messages(startingWith prefix: String) -> [String] {
        capture.lines.map(\.message).filter { $0.hasPrefix(prefix) }
    }

    /// Test that `confirmSignIn` logs no line with the user's answer
    ///
    /// - Given: a plugin waiting for a password after a password factor selection, whose user pool accepts the answer,
    ///   and a capturing logging plugin at verbose
    /// - When:
    ///    - I confirm sign-in with the password
    /// - Then:
    ///    - the user pool receives the password, and the sign-in completes
    ///    - the "Checking next step for:" line prints the challenge state while the answer is verified, and no log
    ///      line holds the password, in full or masked
    ///
    func testConfirmSignInLogsNoLineWithTheAnswer() async throws {
        let challenge = RespondToAuthChallenge(
            challenge: .password,
            availableChallenges: [],
            username: "username",
            session: "session",
            parameters: [:]
        )
        let userPool = MockIdentityProvider(mockRespondToAuthChallengeResponse: { input in
            XCTAssertEqual(input.challengeResponses?["PASSWORD"], Self.answer)
            return .testData()
        })
        let plugin = configureCustomPluginWith(
            userPool: { userPool },
            initialState: .configured(
                .signingIn(.resolvingChallenge(
                    .waitingForAnswer(challenge, .apiBased(.userAuth), .confirmSignInWithPassword),
                    .passwordRequired,
                    .apiBased(.userAuth)
                )),
                .configured,
                .notStarted
            )
        )

        let result = try await plugin.confirmSignIn(challengeResponse: Self.answer)

        XCTAssertTrue(result.isSignedIn)
        let verifying = messages(startingWith: "Checking next step for: resolvingChallenge(")
            .filter { $0.contains("SignInChallengeState.verifying(") }
        XCTAssertFalse(verifying.isEmpty, "\(capture.lines.map(\.message))")
        assertNoLineHolds([], answers: [Self.answer])
    }

    /// Test that confirming a TOTP setup logs no line with the TOTP code or the verified session
    ///
    /// - Given: a plugin waiting for the code of a TOTP setup, whose user pool verifies the code with a new session and
    ///   accepts that session, and a capturing logging plugin at verbose
    /// - When:
    ///    - I confirm sign-in with the code
    /// - Then:
    ///    - the user pool receives the verified session, and the sign-in completes
    ///    - `VerifyTOTPSetup`'s "Sending event" line shows the session `<REDACTED>`, and no log line holds the session,
    ///      nor the code in full or masked
    ///
    func testConfirmingATOTPSetupLogsNoLineWithTheCodeOrTheSession() async throws {
        let code = "482913"
        let userPool = MockIdentityProvider(
            mockRespondToAuthChallengeResponse: { input in
                XCTAssertEqual(input.session, Self.totpSession)
                return .testData()
            },
            mockVerifySoftwareTokenResponse: { input in
                XCTAssertEqual(input.userCode, code)
                return .init(session: Self.totpSession, status: .success)
            }
        )
        let plugin = configureCustomPluginWith(
            userPool: { userPool },
            initialState: .configured(
                .signingIn(.resolvingTOTPSetup(
                    .waitingForAnswer(.init(secretCode: "sharedSecret", session: "session", username: "username")),
                    .testData
                )),
                .configured,
                .notStarted
            )
        )

        let result = try await plugin.confirmSignIn(challengeResponse: code)

        XCTAssertTrue(result.isSignedIn)
        let sent = capture.lines.map(\.message).filter { $0.contains("VerifyTOTPSetup.swift Sending event") }
        XCTAssertEqual(sent.count, 1, "\(capture.lines.map(\.message))")
        XCTAssertTrue(sent.first?.contains(#"respondToAuthChallenge("<REDACTED>")"#) == true, sent.first ?? "-")
        assertNoLineHolds([Self.totpSession], answers: [code])
    }

    /// Test that the sign-up results that carry the auto sign-in session log it redacted
    ///
    /// - Given: a signed-out plugin whose user pool answers a passwordless sign-up as confirmed with a session, and a
    ///   confirmation with another session, and a capturing logging plugin at verbose
    /// - When:
    ///    - I sign up, then confirm the sign-up
    /// - Then:
    ///    - each result is `.completeAutoSignIn` with its session in full
    ///    - each task's result line, at info, shows `completeAutoSignIn("<REDACTED>")`, and no log line holds either
    ///      session in full (the sign-up state's line masks it, as before)
    ///
    func testTheSignUpResultsLogTheAutoSignInSessionRedacted() async throws {
        let confirmSession = "confirm-sign-up-session-value"
        let userPool = MockIdentityProvider(
            mockSignUpResponse: { _ in
                .init(codeDeliveryDetails: nil, session: Self.signUpSession, userConfirmed: true, userSub: "sub")
            },
            mockConfirmSignUpResponse: { _ in .init(session: confirmSession) }
        )
        let plugin = configureCustomPluginWith(
            userPool: { userPool },
            initialState: .configured(.signedOut(.init(lastKnownUserName: nil)), .configured, .notStarted)
        )

        let signUp = try await plugin.signUp(username: "jeffb", options: .init())
        let confirmed = try await plugin.confirmSignUp(for: "jeffb", confirmationCode: "123456", options: .init())

        guard case .completeAutoSignIn(let signUpSession) = signUp.nextStep,
              case .completeAutoSignIn(let confirmedSession) = confirmed.nextStep else {
            return XCTFail("expected .completeAutoSignIn, got \(signUp.nextStep) and \(confirmed.nextStep)")
        }
        XCTAssertEqual(signUpSession, Self.signUpSession)
        XCTAssertEqual(confirmedSession, confirmSession)
        for eventName in [HubPayload.EventName.Auth.signUpAPI, HubPayload.EventName.Auth.confirmSignUpAPI] {
            let resultLines = capture.lines.filter {
                $0.message.hasPrefix("Successfully completed execution for \(eventName) with result:")
            }
            XCTAssertEqual(resultLines.count, 1, eventName)
            XCTAssertEqual(resultLines.first?.level, "info", eventName)
            XCTAssertTrue(
                resultLines.first?.message.contains(#"completeAutoSignIn("<REDACTED>")"#) == true,
                resultLines.first?.message ?? "-"
            )
        }
        assertNoLineHolds([Self.signUpSession, confirmSession])
    }
}
