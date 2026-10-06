//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyCognitoClient
import XCTest

/// Parity MF-1 and MF-2: the plugin's `TOTPSetupWhenAuthenticatedTests`,
/// with their names, on U-DEF through the client.
final class TOTPSetupTests: ClientMFATestCase {

    /// MF-1: TOTP set up while signed in.
    ///
    /// - Given: a fresh user signed in through the client
    /// - When:
    ///    - `setUpTOTP()`, then `verifyTOTPSetup(code:)` with a code from the secret
    /// - Then:
    ///    - both succeed; the details name the user, and give an `otpauth` URI for an authenticator app
    ///    - the session stays signed in as the user
    ///
    func testSuccessfulTOTPSetupWhileAuthenticated() async throws {
        let (client, user) = try await signedInFreshUser("mf-1")

        let details = try await client.setUpTOTP()
        let secret = TOTPSecret(details.sharedSecret)
        user.recordTOTPSecret(secret)
        try await client.verifyTOTPSetup(code: TOTP.freshCode(secret: secret))

        XCTAssertTrue(details.username == user.username, "the details name the signed-in user")
        XCTAssertFalse(details.sharedSecret.isEmpty, "the setup has a secret")
        let uri = try details.getSetupURI(appName: "CognitoClientIntegrationTests")
        XCTAssertEqual(uri.scheme, "otpauth")
        let state = await client.currentSessionState()
        guard case .signedIn(let signedIn) = state else {
            return XCTFail("the session should stay signed in")
        }
        XCTAssertTrue(signedIn.username == user.username, "the session is signed in as the same user")
    }

    /// MF-2: a wrong code first, then the right one.
    ///
    /// - Given: a fresh user signed in through the client, with a TOTP setup started
    /// - When:
    ///    - `verifyTOTPSetup(code:)` with a code the secret does not produce, then with a right one
    /// - Then:
    ///    - the first throws `.service(.softwareTokenMFANotEnabled, …)`, as the plugin's test expects
    ///    - the second succeeds, with a device name
    ///
    func testSuccessfulTOTPSetupWithInitialError() async throws {
        let (client, user) = try await signedInFreshUser("mf-2")
        let details = try await client.setUpTOTP()
        let secret = TOTPSecret(details.sharedSecret)
        user.recordTOTPSecret(secret)

        do {
            try await client.verifyTOTPSetup(code: TOTP.wrongCode(secret: secret))
            XCTFail("a wrong code should not verify the setup")
        } catch {
            guard case .service(.softwareTokenMFANotEnabled?, _, _, _) = error as? AuthClientError else {
                return XCTFail("expected .service(.softwareTokenMFANotEnabled), got \(Self.describe(error))")
            }
        }
        try await client.verifyTOTPSetup(
            code: TOTP.freshCode(secret: secret),
            options: .init(friendlyDeviceName: "ccit-mf-2")
        )
    }
}
