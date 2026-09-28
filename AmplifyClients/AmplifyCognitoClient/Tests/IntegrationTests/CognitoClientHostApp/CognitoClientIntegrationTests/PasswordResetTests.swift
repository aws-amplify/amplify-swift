//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyCognitoClient
import XCTest

/// The plugin's `AuthResetPasswordTests` and `AuthConfirmResetPasswordTests`, through the client
/// (RP-1 and RP-2), on `default`, whose app client prevents user-existence errors.
/// Both plugin tests are named `testUserNotFoundResetPassword`; in one suite here, RP-2 is
/// `testUserNotFoundConfirmResetPassword`.
///
/// No test prints a username, password or code.
final class PasswordResetTests: ClientIntegrationTestCase {

    /// A reset for a user who does not exist gets Cognito's simulated answer (RP-1).
    ///
    /// - Given: a username never registered on `default`
    /// - When:
    ///    - the client resets its password
    /// - Then:
    ///    - the result is not reset, `.confirmResetPasswordWithCode`: existence errors are prevented, so
    ///      Cognito simulates a delivery. As the plugin's test, `.service(.userNotFound)` or
    ///      `.service(.limitExceeded)` is accepted too
    ///
    func testUserNotFoundResetPassword() async throws {
        let client = try makeClient("rp-1", pool: .standard)

        do {
            let result = try await client.resetPassword(for: SandboxSignUp.identity().username)
            XCTAssertFalse(result.isPasswordReset)
            guard case .confirmResetPasswordWithCode = result.nextStep else {
                return XCTFail("expected .confirmResetPasswordWithCode")
            }
        } catch AuthClientError.service(let code?, _, _, _) where [.userNotFound, .limitExceeded].contains(code) {
            return
        } catch {
            XCTFail("expected a simulated delivery, .userNotFound or .limitExceeded; got \(ClientErrorShape.of(error))")
        }
    }

    /// Confirming a reset for a user who does not exist fails (RP-2).
    ///
    /// - Given: a username never registered on `default`
    /// - When:
    ///    - the client confirms a reset for it with a new password and a code
    /// - Then:
    ///    - it throws `.service` with `userNotFound`, `codeExpired` (existence errors prevented) or
    ///      `limitExceeded`, as the plugin's test accepts
    ///
    func testUserNotFoundConfirmResetPassword() async throws {
        let client = try makeClient("rp-2", pool: .standard)

        do {
            try await client.confirmResetPassword(
                for: SandboxSignUp.identity().username,
                with: SandboxSignUp.freshPassword(),
                confirmationCode: "123"
            )
            XCTFail("confirmResetPassword for a user who does not exist should fail")
        } catch AuthClientError.service(let code?, _, _, _) where [.userNotFound, .codeExpired, .limitExceeded].contains(code) {
            return
        } catch {
            XCTFail("expected .userNotFound, .codeExpired or .limitExceeded; got \(ClientErrorShape.of(error))")
        }
    }

    /// A whole reset: the code Cognito sends resets the password, and the user signs in with the new one
    /// (extra, not counted: no plugin test runs a reset end to end).
    ///
    /// - Given: a fresh user on `default`, whose email is verified
    /// - When:
    ///    - the client resets the password; the code arrives at the sink; the client confirms the reset
    ///      with it and a new password, then signs the user in with the new password
    /// - Then:
    ///    - the reset reports the code sent to the email; the sign-in is `.done` as that user
    ///
    func testSuccessfulResetPasswordEndToEnd() async throws {
        let user = try await makeFreshUser(on: .standard)
        let client = try makeClient("rp-3", pool: .standard)
        let sink = try CodeSink()
        let newPassword = SandboxSignUp.freshPassword()

        let (result, code) = try await sink.code(for: user, .resetPassword) {
            try await client.resetPassword(for: user.username, options: .init(clientMetadata: ["mydata": "myvalue"]))
        }
        guard case .confirmResetPasswordWithCode(let details, _) = result.nextStep else {
            return XCTFail("expected .confirmResetPasswordWithCode")
        }
        guard case .email = details.destination else {
            return XCTFail("expected the code to go to the email")
        }
        XCTAssertFalse(result.isPasswordReset)
        try await client.confirmResetPassword(for: user.username, with: newPassword, confirmationCode: code)
        user.recordPassword(newPassword)

        let signIn = try await client.signIn(username: user.username, password: newPassword)
        XCTAssertEqual(signIn.nextStep, .done)
        let signedIn = try await client.getCurrentUser()
        XCTAssertTrue(signedIn.username.lowercased() == user.username.lowercased(), "the new password signs the user in")
    }
}
