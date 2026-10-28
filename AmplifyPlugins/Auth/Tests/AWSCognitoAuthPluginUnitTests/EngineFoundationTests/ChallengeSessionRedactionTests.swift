//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation
import XCTest
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// The challenge a sign-in answers prints with its session redacted in every form: the sign-in actions log the
/// events that carry it at verbose by string interpolation, and states that hold it can be dumped.
final class ChallengeSessionRedactionTests: XCTestCase {

    private static let session = "challenge-session-value"
    private static let username = "challenge-probe-user"
    private static let inputUsername = "challenge-input-user"

    private let challenge = RespondToAuthChallenge(
        challenge: .smsMfa,
        availableChallenges: [.smsMfa],
        username: username,
        session: session,
        parameters: ["CODE_DELIVERY_DELIVERY_MEDIUM": "SMS"],
        inputUsername: inputUsername
    )

    /// Every printed form of `value`: `print`, `debugPrint`, string interpolation and `dump`.
    private func printedForms(of value: Any) -> [String] {
        var printed = ""
        print(value, to: &printed)
        var debugPrinted = ""
        debugPrint(value, to: &debugPrinted)
        var dumped = ""
        dump(value, to: &dumped)
        return [printed, debugPrinted, "\(value)", dumped]
    }

    /// Fails for every form of `value` that holds one of `clear`: by default the session or a username, in full.
    private func assertRedacted(
        _ value: Any,
        clear: [String] = [session, username, inputUsername],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for form in printedForms(of: value) {
            for clear in clear where form.contains(clear) {
                XCTFail("a printed form holds \(clear): \(form)", file: file, line: line)
            }
        }
    }

    /// Test that the challenge prints without its session
    ///
    /// - Given: a challenge with a session, a username and an input username
    /// - When:
    ///    - it is printed with `print`, `debugPrint`, interpolation and `dump`
    /// - Then:
    ///    - no form holds the session or a username
    ///    - `description` and `debugDescription` read as default printing does, with the session `<REDACTED>` and the
    ///      usernames masked, and `dump` names each field with the same values
    ///
    func testTheChallengePrintsWithoutItsSession() {
        assertRedacted(challenge)
        XCTAssertEqual(challenge.debugDescription, challenge.description)
        let username = Self.username.maskedForLog()
        let inputUsername = Self.inputUsername.maskedForLog()
        XCTAssertEqual(
            challenge.description,
            "InternalAWSCognitoAuth.RespondToAuthChallenge(challenge: "
                + "AWSCognitoIdentityProvider.CognitoIdentityProviderClientTypes.ChallengeNameType.smsMfa, "
                + "availableChallenges: [AWSCognitoIdentityProvider.CognitoIdentityProviderClientTypes.ChallengeNameType.smsMfa], "
                + #"username: "\#(username)", session: Optional("<REDACTED>"), "#
                + #"parameters: Optional(["CODE_DELIVERY_DELIVERY_MEDIUM": "SMS"]), inputUsername: Optional("\#(inputUsername)"))"#
        )

        var dumped = ""
        dump(challenge, to: &dumped)
        XCTAssertTrue(dumped.contains(#"session: Optional("<REDACTED>")"#), dumped)
        XCTAssertTrue(dumped.contains(#"- username: "\#(username)""#), dumped)
        XCTAssertTrue(dumped.contains(#"inputUsername: Optional("\#(inputUsername)")"#), dumped)
        for field in ["challenge", "availableChallenges", "parameters"] {
            XCTAssertTrue(dumped.contains(" \(field): "), dumped)
        }
    }

    /// Test that a challenge without a session prints its session as `nil`
    ///
    /// - Given: a challenge with no session
    /// - When:
    ///    - it is printed and dumped
    /// - Then:
    ///    - the session is `nil`, as default printing shows it
    ///
    func testAChallengeWithoutASessionPrintsANilSession() {
        let challenge = RespondToAuthChallenge(challenge: .smsMfa, availableChallenges: [], username: "u", session: nil, parameters: nil)

        XCTAssertTrue(challenge.description.contains("session: nil, "), challenge.description)
        var dumped = ""
        dump(challenge, to: &dumped)
        XCTAssertTrue(dumped.contains("- session: nil"), dumped)
    }

    /// Test that the events and states that carry the challenge print without its session
    ///
    /// - Given: each sign-in event that carries the challenge, and the states that hold it
    /// - When:
    ///    - each is interpolated as a "Sending event" line does, and printed in every other form
    /// - Then:
    ///    - no form holds the session; no state, and no event but the TOTP setup's (which carries the username
    ///      beside the challenge), holds a username
    ///
    func testTheEventsAndStatesThatCarryTheChallengePrintWithoutItsSession() {
        let events: [Any] = [
            SignInEvent(id: "event-1", eventType: .receivedChallenge(challenge)),
            SignInEvent(id: "event-2", eventType: .initiateTOTPSetup(Self.username, challenge)),
            SignInEvent(
                id: "event-3",
                eventType: .initiateSignInWithSRP(
                    SignInEventData(username: nil, password: nil, signInMethod: .apiBased(.userSRP)),
                    .noData,
                    challenge
                )
            ),
            SetUpTOTPEvent(id: "event-4", eventType: .setUpTOTP(challenge))
        ]
        for event in events {
            let line = "InternalAWSCognitoAuth/VerifyPasswordSRP.swift Sending event \(event)"
            XCTAssertFalse(line.contains(Self.session), line)
            XCTAssertTrue(line.contains(#"session: Optional("<REDACTED>")"#), line)
            if case .initiateTOTPSetup? = (event as? SignInEvent)?.eventType {
                assertRedacted(event, clear: [Self.session, Self.inputUsername])
            } else {
                assertRedacted(event)
            }
        }

        let states: [Any] = [
            SignInChallengeState.waitingForAnswer(challenge, .apiBased(.userSRP), .confirmSignInWithTOTPCode),
            SignInState.resolvingChallenge(
                .waitingForAnswer(challenge, .apiBased(.userSRP), .confirmSignInWithTOTPCode),
                .smsMfa,
                .apiBased(.userSRP)
            )
        ]
        for state in states {
            assertRedacted(state)
        }
    }

    /// Test that the line `VerifyPasswordSRP` logs for the challenge it sends holds no session
    ///
    /// - Given: `VerifyPasswordSRP` over a user pool whose `RespondToAuthChallenge` answers an SMS MFA challenge with a
    ///   session, and a capturing logger as the environment's
    /// - When:
    ///    - the action runs
    /// - Then:
    ///    - it sends the challenge, with its session
    ///    - its "Sending event" line shows the session as `<REDACTED>`, and no line holds it
    ///
    func testTheVerifyPasswordLineHoldsNoSession() async throws {
        let router = CapturingRouter()
        let defaults = Defaults.makeDefaultAuthEnvironment(userPoolFactory: {
            MockIdentityProvider(mockRespondToAuthChallengeResponse: { _ in
                RespondToAuthChallengeOutput(
                    challengeName: .smsMfa,
                    challengeParameters: ["CODE_DELIVERY_DELIVERY_MEDIUM": "SMS"],
                    session: Self.session
                )
            })
        })
        let environment = AuthEnvironment(
            configuration: defaults.configuration,
            userPoolConfigData: defaults.userPoolConfigData,
            identityPoolConfigData: defaults.identityPoolConfigData,
            authenticationEnvironment: defaults.authenticationEnvironment,
            authorizationEnvironment: defaults.authorizationEnvironment,
            credentialsClient: defaults.credentialsClient,
            logger: router.scopedLogger()
        )
        let action = VerifyPasswordSRP(stateData: .testData, authResponse: InitiateAuthOutput.validTestData, clientMetadata: [:])
        let sent = expectation(description: "the challenge is sent")
        let dispatcher = MockDispatcher { event in
            guard case .receivedChallenge(let challenge) = (event as? SignInEvent)?.eventType else {
                return
            }
            XCTAssertEqual(challenge.session, Self.session)
            sent.fulfill()
        }

        await action.execute(withDispatcher: dispatcher, environment: environment)

        await fulfillment(of: [sent], timeout: 1)
        let messages = router.entries.map(\.message)
        XCTAssertFalse(messages.contains { $0.contains(Self.session) }, "\(messages)")
        let line = try XCTUnwrap(messages.first { $0.contains("VerifyPasswordSRP.swift Sending event") }, "\(messages)")
        XCTAssertTrue(line.contains(#"session: Optional("<REDACTED>")"#), line)
    }

    /// Test that the error of an MFA setup the plugin cannot continue carries the challenge without its session
    ///
    /// - Given: an MFA setup challenge with a session and a username that offers only SMS, which the plugin does not
    ///   set up
    /// - When:
    ///    - the sign-in resolves the challenge's next step
    /// - Then:
    ///    - it fails with `SignInError.unknown`, whose message, and the `AuthError.unknown` the plugin throws with it,
    ///      holds the challenge as it prints: the session `<REDACTED>`, the usernames masked
    ///
    func testAnUnresolvableMFASetupErrorHoldsTheChallengeWithoutItsSession() async throws {
        let challenge = RespondToAuthChallenge(
            challenge: .mfaSetup,
            availableChallenges: [],
            username: Self.username,
            session: Self.session,
            parameters: ["MFAS_CAN_SETUP": #"["SMS_MFA"]"#],
            inputUsername: Self.inputUsername
        )
        let action = InitializeResolveChallenge(challenge: challenge, signInMethod: .apiBased(.userSRP))
        let failed = expectation(description: "the sign-in fails")
        let messages = RecordedMessages()
        let dispatcher = MockDispatcher { event in
            guard case .throwAuthError(let error) = (event as? SignInEvent)?.eventType else {
                return
            }
            guard case .unknown(let message) = error else {
                return XCTFail("the sign-in failed with \(error), not unknown")
            }
            messages.append(message)
            messages.append(error.authError.errorDescription)
            failed.fulfill()
        }

        await action.execute(withDispatcher: dispatcher, environment: Defaults.makeDefaultAuthEnvironment())

        await fulfillment(of: [failed], timeout: 1)
        let recorded = messages.all
        XCTAssertEqual(recorded.count, 2)
        for message in recorded {
            XCTAssertTrue(message.contains(challenge.description), message)
            XCTAssertTrue(message.contains(#"session: Optional("<REDACTED>")"#), message)
            for clear in [Self.session, Self.username, Self.inputUsername] {
                XCTAssertFalse(message.contains(clear), "\(clear) in \(message)")
            }
        }
    }
}

/// The messages a dispatcher's events carried, from its `@Sendable` callback.
private final class RecordedMessages: @unchecked Sendable {
    private let lock = NSLock()
    private var messages: [String] = []

    var all: [String] {
        lock.withLock { messages }
    }

    func append(_ message: String) {
        lock.withLock { messages.append(message) }
    }
}
