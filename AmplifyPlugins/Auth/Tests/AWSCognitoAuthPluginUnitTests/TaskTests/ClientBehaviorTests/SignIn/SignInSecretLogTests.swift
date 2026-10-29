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

/// The plugin logs none of a sign-in's secrets, at any level: the user's answer to `confirmSignIn` reaches the
/// verbose "Checking next step for:" and "Sending event" lines inside the states and events that carry it.
final class SignInSecretLogTests: BasePluginTest, @unchecked Sendable {

    private static let answer = "S3cret-4821"

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
}
