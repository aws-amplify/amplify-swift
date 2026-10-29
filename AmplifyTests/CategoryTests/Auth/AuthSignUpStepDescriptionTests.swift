//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import XCTest

/// `AuthSignUpStep` prints the auto sign-in session redacted in every form: the plugin logs sign-up results by string
/// interpolation, and with the username the session signs the user in.
final class AuthSignUpStepDescriptionTests: XCTestCase {

    private static let session = "auto-sign-in-session-value"

    /// Every printed form of `value`: `print`, `debugPrint`, string interpolation and `dump`.
    private func printedForms(of value: Any) -> [String] {
        var dumped = ""
        dump(value, to: &dumped)
        var printed = ""
        print(value, to: &printed)
        var debugPrinted = ""
        debugPrint(value, to: &debugPrinted)
        return [String(describing: value), String(reflecting: value), "\(value)", dumped, printed, debugPrinted]
    }

    /// Fails for every printed form of `value` that holds the session.
    private func assertRedacted(_ value: Any, file: StaticString = #filePath, line: UInt = #line) {
        for form in printedForms(of: value) where form.contains(Self.session) {
            XCTFail("a printed form holds the session: \(form)", file: file, line: line)
        }
    }

    /// Test that the auto sign-in step prints without its session
    ///
    /// - Given: the `completeAutoSignIn` sign-up step holding a session
    /// - When:
    ///    - it is printed with `description`, `debugDescription`, `String(reflecting:)`, interpolation, `print`,
    ///      `debugPrint` and `dump`
    /// - Then:
    ///    - no form holds the session
    ///    - `description` and `debugDescription` read as default enum printing, with the session `<REDACTED>`
    ///    - `dump` shows the session `<REDACTED>`
    ///
    func testTheAutoSignInStepPrintsWithoutTheSession() {
        let step = AuthSignUpStep.completeAutoSignIn(Self.session)

        assertRedacted(step)
        XCTAssertEqual(step.description, #"completeAutoSignIn("<REDACTED>")"#)
        XCTAssertEqual(step.debugDescription, #"Amplify.AuthSignUpStep.completeAutoSignIn("<REDACTED>")"#)
        XCTAssertEqual(String(reflecting: step), step.debugDescription)

        var dumped = ""
        dump(step, to: &dumped)
        XCTAssertTrue(dumped.contains(#"- completeAutoSignIn: "<REDACTED>""#), dumped)
    }

    /// Test that the other steps print as default enum printing does
    ///
    /// - Given: `confirmUser` with delivery details, additional information and a user ID; `confirmUser` with none;
    ///   and `done`
    /// - When:
    ///    - each is printed with `description` and `debugDescription`
    /// - Then:
    ///    - each reads as default enum printing would
    ///
    func testTheOtherStepsPrintAsBefore() {
        let details = AuthCodeDeliveryDetails(destination: .email("a@example.com"))
        let step = AuthSignUpStep.confirmUser(details, ["key": "value"], "sub")

        XCTAssertEqual(
            step.description,
            "confirmUser(\(String(reflecting: Optional(details))), "
                + #"Optional(["key": "value"]), Optional("sub"))"#
        )
        XCTAssertEqual(step.debugDescription, "Amplify.AuthSignUpStep.\(step.description)")
        XCTAssertEqual(AuthSignUpStep.confirmUser().description, "confirmUser(nil, nil, nil)")
        XCTAssertEqual(AuthSignUpStep.done.description, "done")
        XCTAssertEqual(AuthSignUpStep.done.debugDescription, "Amplify.AuthSignUpStep.done")

        var dumped = ""
        dump(step, to: &dumped)
        XCTAssertTrue(dumped.contains(#" .2: Optional("sub")"#), dumped)
    }

    /// Test that the sign-up result carrying the auto sign-in step prints without the session
    ///
    /// - Given: a sign-up result holding the `completeAutoSignIn` step, as `signUp` and `confirmSignUp` return it and
    ///   the plugin logs it
    /// - When:
    ///    - the result, and the result's line as the plugin logs it, are printed in every form
    /// - Then:
    ///    - no form holds the session, the line shows it `<REDACTED>`, and the app still reads it from the step
    ///
    func testTheResultPrintsWithoutTheSession() {
        let result = AuthSignUpResult(.completeAutoSignIn(Self.session), userID: "sub")

        assertRedacted(result)
        assertRedacted([result])
        assertRedacted(Optional(result) as Any)

        let line = "Successfully completed execution for Auth.confirmSignUpAPI with result:\n\(result)"
        XCTAssertFalse(line.contains(Self.session), line)
        XCTAssertTrue(line.contains(#"completeAutoSignIn("<REDACTED>")"#), line)
        guard case .completeAutoSignIn(let session) = result.nextStep else {
            return XCTFail("expected .completeAutoSignIn, got \(result.nextStep)")
        }
        XCTAssertEqual(session, Self.session)
    }
}
