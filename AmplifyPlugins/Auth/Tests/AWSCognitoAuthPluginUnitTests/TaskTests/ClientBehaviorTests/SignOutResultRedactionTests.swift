//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
@testable import AWSCognitoAuthPlugin
import Foundation
@testable import InternalAWSCognitoAuth
import XCTest

/// A sign-out that could not revoke the refresh token, or sign out globally, reports the still-valid token in
/// its result, and the sign-out task logs that result at info. Every printed form masks the token.
final class SignOutResultRedactionTests: XCTestCase {

    private let refreshToken = "redaction-test-refresh-token"
    private let accessToken = "redaction-test-access-token"

    /// Every printed form of a value: interpolation, `print`, `debugPrint` and `dump`.
    private func printedForms(_ value: some Any) -> [String: String] {
        var dumped = ""
        dump(value, to: &dumped)
        return [
            "String(describing:)": String(describing: value),
            "String(reflecting:)": String(reflecting: value),
            "interpolation": "\(value)",
            "dump": dumped
        ]
    }

    private func assertNoToken(in value: some Any, _ context: String, file: StaticString = #filePath, line: UInt = #line) {
        for (form, text) in printedForms(value) {
            XCTAssertFalse(text.contains(refreshToken), "\(context), \(form): \(text)", file: file, line: line)
            XCTAssertFalse(text.contains(accessToken), "\(context), \(form): \(text)", file: file, line: line)
        }
    }

    /// Test that the plugin's sign-out error results never print the token they carry
    ///
    /// - Given: An `AWSCognitoRevokeTokenError`, an `AWSCognitoGlobalSignOutError`, and a partial result
    ///   holding both
    /// - When:
    ///    - Each is printed with `String(describing:)`, `String(reflecting:)` (`debugDescription`),
    ///      interpolation and `dump()`
    /// - Then:
    ///    - No form contains either token
    ///    - The error is still printed, and `debugDescription` reads as the default struct printing did,
    ///      with the token masked
    ///
    func testPluginSignOutErrorsNeverPrintTheirToken() {
        let revoke = AWSCognitoRevokeTokenError(refreshToken: refreshToken, error: .unknown("revoke failed", nil))
        let global = AWSCognitoGlobalSignOutError(accessToken: accessToken, error: .unknown("global failed", nil))
        let result = AWSCognitoSignOutResult.partial(revokeTokenError: revoke, globalSignOutError: global, hostedUIError: nil)

        assertNoToken(in: revoke, "revoke")
        assertNoToken(in: global, "global")
        assertNoToken(in: result, "partial result")
        XCTAssertEqual(
            revoke.debugDescription,
            "AWSCognitoAuthPlugin.AWSCognitoRevokeTokenError(refreshToken: \"re*****en\", error: \(String(reflecting: revoke.error)))"
        )
        XCTAssertEqual(
            global.debugDescription,
            "AWSCognitoAuthPlugin.AWSCognitoGlobalSignOutError(accessToken: \"re*****en\", error: \(String(reflecting: global.error)))"
        )
        XCTAssertTrue(String(describing: result).contains("revoke failed"))
        XCTAssertEqual(Mirror(reflecting: revoke).children.map(\.label), ["refreshToken", "error"])
        XCTAssertEqual(Mirror(reflecting: global).children.map(\.label), ["accessToken", "error"])
    }

    /// Test that the engine's sign-out failure payloads never print the token they carry
    ///
    /// - Given: An `EngineRevokeTokenFailure` and an `EngineGlobalSignOutFailure`
    /// - When:
    ///    - Each is printed with `String(describing:)`, `String(reflecting:)` (`debugDescription`),
    ///      interpolation and `dump()`
    /// - Then:
    ///    - No form contains either token, and the error is still printed
    ///
    func testEngineSignOutFailuresNeverPrintTheirToken() {
        let revoke = EngineRevokeTokenFailure(refreshToken: refreshToken, error: .unknown("revoke failed"))
        let global = EngineGlobalSignOutFailure(accessToken: accessToken, error: .unknown("global failed"))

        assertNoToken(in: revoke, "engine revoke")
        assertNoToken(in: global, "engine global")
        assertNoToken(in: [revoke] as [Any] + [global], "engine failures in a collection")
        XCTAssertTrue(revoke.debugDescription.contains("refreshToken: \"re*****en\""), revoke.debugDescription)
        XCTAssertTrue(global.debugDescription.contains("accessToken: \"re*****en\""), global.debugDescription)
        XCTAssertTrue(revoke.debugDescription.contains("revoke failed"), revoke.debugDescription)
        XCTAssertTrue(global.debugDescription.contains("global failed"), global.debugDescription)
    }
}
