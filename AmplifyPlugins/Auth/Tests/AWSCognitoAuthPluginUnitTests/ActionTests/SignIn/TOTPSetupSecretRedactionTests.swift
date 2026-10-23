//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import InternalAWSCognitoAuth

/// The engine's values that carry a TOTP shared secret print it redacted in every form: `SetUpTOTP` logs the event it
/// sends at verbose by string interpolation, and states and steps that hold the values can be dumped.
final class TOTPSetupSecretRedactionTests: XCTestCase {

    private static let secret = "JBSWY3DPEHPK3PXPJBSWY3DPEHPK3PXP"
    private static let session = "totp-setup-session-value"
    private static let username = "totp-probe-user"

    private let setup = SignInTOTPSetupData(secretCode: secret, session: session, username: username)

    /// Every printed form of `value`: `print`, `debugPrint`, string interpolation and `dump`.
    private func printedForms(of value: Any) -> [String] {
        var dumped = ""
        dump(value, to: &dumped)
        return [String(describing: value), String(reflecting: value), "\(value)", dumped]
    }

    /// Fails for every form of `value` that holds one of `clear`: by default the secret, the session or the username,
    /// in full.
    private func assertRedacted(
        _ value: Any,
        clear: [String] = [secret, session, username],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for form in printedForms(of: value) {
            for clear in clear where form.contains(clear) {
                XCTFail("a printed form holds \(clear): \(form)", file: file, line: line)
            }
        }
    }

    /// Test that the TOTP setup data prints without its secret
    ///
    /// - Given: TOTP setup data with a shared secret, a session and a username
    /// - When:
    ///    - it is printed with `description`, `debugDescription`, `String(reflecting:)`, interpolation and `dump`
    /// - Then:
    ///    - no form holds the secret, the session or the username
    ///    - `description` and `debugDescription` are the redacted debug dictionary, and `dump` names each field
    ///
    func testTheSetupDataPrintsWithoutTheSecret() {
        assertRedacted(setup)
        XCTAssertEqual(setup.description, setup.debugDictionary.debugDescription)
        XCTAssertEqual(setup.debugDescription, setup.description)
        XCTAssertTrue(setup.description.contains(#""sharedSecret": "<REDACTED>""#), setup.description)

        var dumped = ""
        dump(setup, to: &dumped)
        XCTAssertTrue(dumped.contains(#"- secretCode: "<REDACTED>""#), dumped)
        XCTAssertTrue(dumped.contains(#"- session: "to********************ue""#), dumped)
        XCTAssertTrue(dumped.contains(#"- username: "to***********er""#), dumped)
    }

    /// Test that the line `SetUpTOTP` logs for the event it sends holds no secret
    ///
    /// - Given: the `waitForAnswer` event `SetUpTOTP` sends once Cognito answers with a secret
    /// - When:
    ///    - the event is interpolated as `SetUpTOTP` logs it, reflected and dumped
    /// - Then:
    ///    - no form holds the secret, the session or the username, and the line shows the secret as `<REDACTED>`
    ///
    func testTheSentEventLinePrintsWithoutTheSecret() {
        let event = SetUpTOTPEvent(id: "event-1", eventType: .waitForAnswer(setup))
        let line = "InternalAWSCognitoAuth/SetUpTOTP.swift Sending event \(event)"

        XCTAssertFalse(line.contains(Self.secret), line)
        XCTAssertTrue(line.contains(#".waitForAnswer(["#), line)
        XCTAssertTrue(line.contains(#""sharedSecret": "<REDACTED>""#), line)
        assertRedacted(event)
        assertRedacted(event.eventType)
    }

    /// Test that the TOTP setup states print without the secret
    ///
    /// - Given: the TOTP setup states that hold the setup data: waiting for an answer, verifying, and failed, and the
    ///   sign-in state that holds each, which the plugin's "Checking next step for:" line prints
    /// - When:
    ///    - each is printed in every form, and the setup states through their debug dictionaries
    /// - Then:
    ///    - no form holds the secret, the session or the username
    ///
    func testTheSetupStatesPrintWithoutTheSecret() {
        let answer = ConfirmSignInEventData(
            answer: "123456",
            attributes: [:],
            metadata: nil,
            friendlyDeviceName: nil,
            presentationAnchor: nil
        )
        let states: [SignInTOTPSetupState] = [
            .waitingForAnswer(setup),
            .verifying(setup, answer),
            .error(setup, .unknown(message: "failed"))
        ]

        let signIn = SignInEventData(username: nil, password: nil, signInMethod: .apiBased(.userSRP))

        for state in states {
            assertRedacted(state)
            assertRedacted(state.debugDictionary)
            assertRedacted(SignInState.resolvingTOTPSetup(state, signIn))
            XCTAssertFalse("Checking next step for: \(SignInState.resolvingTOTPSetup(state, signIn))".contains(Self.secret))
        }
    }

    /// Test that the engine's TOTP setup step prints without the secret
    ///
    /// - Given: the engine's TOTP setup details, and the sign-in step that carries them
    /// - When:
    ///    - each is printed with `description`, `debugDescription`, `String(reflecting:)`, interpolation and `dump`
    /// - Then:
    ///    - no form holds the secret, and the details read as default printing would with the secret `<REDACTED>`
    ///
    func testTheEngineSetupDetailsPrintWithoutTheSecret() {
        let details = EngineTOTPSetupDetails(sharedSecret: Self.secret, username: Self.username)

        assertRedacted(details, clear: [Self.secret])
        assertRedacted(EngineSignInStep.continueSignInWithTOTPSetup(details), clear: [Self.secret])
        XCTAssertEqual(
            details.description,
            #"InternalAWSCognitoAuth.EngineTOTPSetupDetails(sharedSecret: "<REDACTED>", username: "totp-probe-user")"#
        )
        XCTAssertEqual(details.debugDescription, details.description)

        var dumped = ""
        dump(details, to: &dumped)
        XCTAssertTrue(dumped.contains(#"- sharedSecret: "<REDACTED>""#), dumped)
    }
}
