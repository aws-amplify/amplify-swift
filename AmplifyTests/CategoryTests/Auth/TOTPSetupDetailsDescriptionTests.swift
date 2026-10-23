//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import XCTest

/// `TOTPSetupDetails` prints its shared secret redacted in every form: the plugin logs sign-in and TOTP setup results
/// by string interpolation, and apps print or dump the details and the steps that carry them.
final class TOTPSetupDetailsDescriptionTests: XCTestCase {

    private static let secret = "JBSWY3DPEHPK3PXPJBSWY3DPEHPK3PXP"
    private static let username = "totp-probe-user"

    private let details = TOTPSetupDetails(sharedSecret: secret, username: username)

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

    /// Fails for every printed form of `value` that holds the secret.
    private func assertRedacted(_ value: Any, file: StaticString = #filePath, line: UInt = #line) {
        for form in printedForms(of: value) where form.contains(Self.secret) {
            XCTFail("a printed form holds the secret: \(form)", file: file, line: line)
        }
    }

    /// Test that the TOTP setup details print without the secret
    ///
    /// - Given: TOTP setup details with a shared secret and a username
    /// - When:
    ///    - they are printed with `description`, `debugDescription`, `String(reflecting:)`, interpolation, `print`,
    ///      `debugPrint` and `dump`
    /// - Then:
    ///    - no form holds the secret
    ///    - `description` and `debugDescription` read as default struct printing, with the secret `<REDACTED>` and
    ///      the username as is
    ///    - `dump` shows the secret `<REDACTED>` and the username
    ///
    func testTheDetailsPrintWithoutTheSecret() {
        assertRedacted(details)
        XCTAssertEqual(
            details.description,
            #"Amplify.TOTPSetupDetails(sharedSecret: "<REDACTED>", username: "totp-probe-user")"#
        )
        XCTAssertEqual(details.debugDescription, details.description)
        XCTAssertEqual(String(reflecting: details), details.description)

        var dumped = ""
        dump(details, to: &dumped)
        XCTAssertTrue(dumped.contains(#"- sharedSecret: "<REDACTED>""#), dumped)
        XCTAssertTrue(dumped.contains(#"- username: "totp-probe-user""#), dumped)
    }

    /// Test that the sign-in step and result carrying TOTP setup details print without the secret
    ///
    /// - Given: the `continueSignInWithTOTPSetup` sign-in step holding TOTP setup details, and a sign-in result
    ///   holding that step, as `confirmSignIn` returns and the plugin logs it
    /// - When:
    ///    - the step, the result, and the result's line as the plugin logs it are printed in every form
    /// - Then:
    ///    - no form holds the secret, and the result shows the secret `<REDACTED>`
    ///
    func testTheEnclosingStepAndResultPrintWithoutTheSecret() {
        let step = AuthSignInStep.continueSignInWithTOTPSetup(details)
        let result = AuthSignInResult(nextStep: step)

        assertRedacted(step)
        assertRedacted(result)
        assertRedacted([result])
        assertRedacted(Optional(result) as Any)

        let line = "Successfully completed execution for Auth.confirmSignInAPI with result:\n\(result)"
        XCTAssertFalse(line.contains(Self.secret), line)
        XCTAssertTrue(line.contains(#"sharedSecret: "<REDACTED>""#), line)
    }

    /// Test that the secret stays available to the app
    ///
    /// - Given: TOTP setup details with a shared secret and a username
    /// - When:
    ///    - the app reads `sharedSecret`, builds the setup URI and compares the details
    /// - Then:
    ///    - `sharedSecret` and the URI hold the secret in full, and equality still compares the secret
    ///
    func testTheSecretStaysAvailableToTheApp() throws {
        XCTAssertEqual(details.sharedSecret, Self.secret)
        XCTAssertEqual(details.username, Self.username)

        let uri = try details.getSetupURI(appName: "app")
        XCTAssertEqual(uri.absoluteString, "otpauth://totp/app:\(Self.username)?secret=\(Self.secret)&issuer=app")

        XCTAssertEqual(details, TOTPSetupDetails(sharedSecret: Self.secret, username: Self.username))
        XCTAssertNotEqual(details, TOTPSetupDetails(sharedSecret: "OTHERSECRET", username: Self.username))
    }
}
