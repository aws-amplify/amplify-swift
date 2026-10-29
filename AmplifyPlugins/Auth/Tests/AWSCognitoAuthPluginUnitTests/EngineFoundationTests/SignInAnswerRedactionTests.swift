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

/// The user's answer to a sign-in challenge (a code, a password after a password factor selection, a new password, a
/// custom answer) prints redacted in every form: the sign-in actions log the events that carry it at verbose by
/// string interpolation, the plugin's "Checking next step for:" and "Auth state change" lines print the states that
/// hold it, and any of them can be dumped.
final class SignInAnswerRedactionTests: XCTestCase {

    private static let answer = "S3cret-4821"

    private let answerData = ConfirmSignInEventData(
        answer: answer,
        attributes: ["custom:city": "Seattle"],
        metadata: ["key": "value"],
        friendlyDeviceName: "device",
        presentationAnchor: nil
    )

    private let challenge = RespondToAuthChallenge(
        challenge: .password,
        availableChallenges: [],
        username: "u",
        session: "challenge-session",
        parameters: [:]
    )

    private let setup = SignInTOTPSetupData(secretCode: "secret", session: "setup-session", username: "u")

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

    /// Fails for every form of `value` that holds one of `clear`.
    private func assertRedacted(
        _ value: Any,
        clear: [String] = [answer],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for form in printedForms(of: value) {
            for clear in clear where form.contains(clear) {
                XCTFail("a printed form holds \(clear): \(form)", file: file, line: line)
            }
        }
    }

    /// Test that a challenge answer prints with the answer redacted
    ///
    /// - Given: the answer `confirmSignIn` sends, with attributes, metadata and a device name
    /// - When:
    ///    - it is printed with `print`, `debugPrint`, interpolation and `dump`, and through its debug dictionary
    /// - Then:
    ///    - no form holds the answer, not even masked: its debug dictionary reads `"answer": "<REDACTED>"`
    ///    - `description` and `debugDescription` are that dictionary, and `dump` names each field, the answer redacted
    ///
    func testTheAnswerPrintsRedacted() {
        assertRedacted(answerData, clear: [Self.answer, Self.answer.maskedForLog()])
        assertRedacted(answerData.debugDictionary, clear: [Self.answer, Self.answer.maskedForLog()])
        XCTAssertEqual(answerData.description, answerData.debugDictionary.debugDescription)
        XCTAssertEqual(answerData.debugDescription, answerData.description)
        XCTAssertTrue(answerData.description.contains(#""answer": "<REDACTED>""#), answerData.description)

        var dumped = ""
        dump(answerData, to: &dumped)
        XCTAssertTrue(dumped.contains(#"- answer: "<REDACTED>""#), dumped)
        for field in ["attributes", "metadata", "friendlyDeviceName", "presentationAnchor"] {
            XCTAssertTrue(dumped.contains(" \(field): "), dumped)
        }
    }

    /// Test that the events and states that carry a challenge answer print without it
    ///
    /// - Given: each event that carries the answer (`verifyChallengeAnswer` and its retry, the TOTP setup's answer),
    ///   the TOTP setup state that holds it, the challenge state while the answer is verified, and the sign-in and auth
    ///   states that hold those
    /// - When:
    ///    - each is printed in every form, as a "Sending event", "Checking next step for:" or "Auth state change" line
    ///      prints it
    /// - Then:
    ///    - no form holds the answer, in full or masked
    ///
    func testTheEventsAndStatesThatCarryTheAnswerPrintWithoutIt() {
        let events: [Any] = [
            SignInChallengeEvent(eventType: .verifyChallengeAnswer(answerData)),
            SignInChallengeEvent(eventType: .retryVerifyChallengeAnswer(answerData, .confirmSignInWithPassword)),
            SetUpTOTPEvent(eventType: .verifyChallengeAnswer(answerData))
        ]
        let signIn = SignInEventData(username: nil, password: nil, signInMethod: .apiBased(.userAuth))
        let signInStates: [SignInState] = [
            .resolvingChallenge(
                .verifying(challenge, .apiBased(.userAuth), .confirmSignInWithPassword),
                .passwordRequired,
                .apiBased(.userAuth)
            ),
            .resolvingTOTPSetup(.verifying(setup, answerData), signIn)
        ]
        let clear = [Self.answer, Self.answer.maskedForLog()]
        for event in events {
            assertRedacted(event, clear: clear)
            let line = "InternalAWSCognitoAuth/VerifySignInChallenge.swift Sending event \(event)"
            XCTAssertFalse(clear.contains { line.contains($0) }, line)
        }
        for state in signInStates {
            assertRedacted(state, clear: clear)
            assertRedacted(state.debugDictionary, clear: clear)
            let checking = "Checking next step for: \(state)"
            XCTAssertFalse(clear.contains { checking.contains($0) }, checking)
            let authState = AuthState.configured(.signingIn(state), .configured, .notStarted)
            let changed = "Auth state change:\n\n\(authState)\n"
            XCTAssertFalse(clear.contains { changed.contains($0) }, changed)
            assertRedacted(authState, clear: clear)
        }
    }
}
