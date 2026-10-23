//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyCognitoClient
import Foundation
import XCTest

/// The base class of the MFA suites (`TOTPSetupTests`, `MFASignInTests`, `MFAPreferenceTests`): a fresh
/// U-DEF user signed in through the client under test, and TOTP enrolled through the client's own
/// `setUpTOTP` / `verifyTOTPSetup`, as the plugin's `AuthSignInHelper.registerAndSignInUser` and
/// `TOTPHelper` do.
///
/// The MFA suites' assertion and failure messages name only a step's case and an error's case and
/// description, never a password, a code, a TOTP secret, a token, a username or a step's associated
/// values.
class ClientMFATestCase: ClientIntegrationTestCase {

    /// A fresh user on `pool` (U-DEF, `default`, unless a test reads a code: then U-PL, `passwordless`, the
    /// backend with the same MFA settings, optional with TOTP and SMS, whose outputs name a code API),
    /// signed in through a new client on its own session. Hold the client in a local; `tearDown` signs the
    /// session out, then deletes the user.
    func signedInFreshUser(
        _ tag: String,
        on pool: SandboxPool = .standard,
        withPhoneNumber: Bool = false
    ) async throws -> (client: AmplifyCognitoClient, user: FreshUser) {
        let user = try await makeFreshUser(on: pool, .init(withPhoneNumber: withPhoneNumber))
        let client = try makeClient(tag, pool: pool)
        let result = try await client.signIn(username: user.username, password: XCTUnwrap(user.password))
        guard case .done = result.nextStep else {
            throw HarnessError.malformedFixture("The fresh user's sign-in stopped at \(Self.name(of: result.nextStep)).")
        }
        return (client, user)
    }

    /// Enrolls TOTP through the client: `setUpTOTP`, then `verifyTOTPSetup` with a code from a step no
    /// earlier call used. The user records the secret, so the cleanup's raw sign-in can answer TOTP.
    @discardableResult
    func enrollTOTP(
        _ client: AmplifyCognitoClient,
        _ user: FreshUser,
        friendlyDeviceName: String? = nil
    ) async throws -> TOTPSecret {
        let details = try await client.setUpTOTP()
        let secret = TOTPSecret(details.sharedSecret)
        // Recorded first: should the verification succeed and the test then fail, cleanup can still answer TOTP.
        user.recordTOTPSecret(secret)
        try await client.verifyTOTPSetup(
            code: TOTP.freshCode(secret: secret),
            options: .init(friendlyDeviceName: friendlyDeviceName)
        )
        return secret
    }

    /// The case of `step`, without its associated values, which may hold a TOTP secret.
    static func name(of step: AuthClientSignInStep) -> String {
        caseName(step)
    }

    /// An error's case and description, for a failure message. The underlying error, which may carry a
    /// request identifier, is left out.
    static func describe(_ error: Error) -> String {
        guard let error = error as? AuthClientError else {
            return String(describing: type(of: error))
        }
        return "\(caseName(error)): \(error.errorDescription)"
    }

    /// An enum value's case name, read by reflection, so no associated value is ever rendered. A case
    /// without associated values has no child, and renders as its name.
    private static func caseName(_ value: Any) -> String {
        Mirror(reflecting: value).children.first?.label ?? "\(value)"
    }
}
