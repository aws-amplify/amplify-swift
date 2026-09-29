//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyCognitoClient
import XCTest

/// Parity MF-3 … MF-6: the plugin's `MFASignInTests`, with their names, on
/// U-DEF through the client. The user sets MFA up through the client, signs out, and signs in again
/// through the client's `signIn` / `confirmSignIn`. Where the plugin stops at the SMS step because it
/// cannot read the message, these confirm with the code the custom SMS sender captured.
///
/// MF-3 and MF-5 read no code and run on U-DEF, as the plugin's do. MF-4 and MF-6 read an SMS code, so they
/// run on U-PL (`passwordless`): the plugin backend with the same MFA settings (optional, TOTP and SMS)
/// whose outputs name a code API; the default backend's name none.
final class MFASignInTests: ClientMFATestCase {

    /// MF-3: sign-in with TOTP MFA.
    ///
    /// - Given: a fresh user who enrolled TOTP through the client, enabled it, and signed out
    /// - When:
    ///    - the user signs in, then confirms with a code from the secret
    /// - Then:
    ///    - the sign-in stops at `confirmSignInWithTOTPCode`, and the confirmation is `.done`
    ///
    func testSignInWithTOTPMFA() async throws {
        let (client, user) = try await signedInFreshUser("mf-3")
        let secret = try await enrollTOTP(client, user)
        try await client.updateMFAPreference(sms: nil, totp: .enabled)
        try await client.signOut()

        let signIn = try await client.signIn(username: user.username, password: XCTUnwrap(user.password))

        guard case .confirmSignInWithTOTPCode = signIn.nextStep else {
            return XCTFail("expected confirmSignInWithTOTPCode, got \(Self.name(of: signIn.nextStep))")
        }
        // A code from a later step than the one the setup used: Cognito rejects a reused code.
        let confirm = try await client.confirmSignIn(challengeResponse: TOTP.freshCode(secret: secret))
        XCTAssertEqual(Self.name(of: confirm.nextStep), "done")
    }

    /// MF-4: sign-in with SMS MFA.
    ///
    /// - Given: a fresh user with a phone number on U-PL, who enabled SMS MFA through the client and signed
    ///   out
    /// - When:
    ///    - the user signs in, then confirms with the code the custom SMS sender captured
    /// - Then:
    ///    - the sign-in stops at `confirmSignInWithSMSMFACode` with an SMS destination, and the
    ///      confirmation is `.done`
    ///
    func testSignInWithSMSMFA() async throws {
        let (client, user) = try await signedInFreshUser("mf-4", on: .passwordless, withPhoneNumber: true)
        try await client.updateMFAPreference(sms: .enabled, totp: nil)
        try await client.signOut()
        let sink = try CodeSink()

        let (signIn, code) = try await sink.code(for: user, .mfa) {
            try await client.signIn(username: user.username, password: XCTUnwrap(user.password))
        }

        guard case .confirmSignInWithSMSMFACode(let delivery, _) = signIn.nextStep else {
            return XCTFail("expected confirmSignInWithSMSMFACode, got \(Self.name(of: signIn.nextStep))")
        }
        guard case .sms(let destination) = delivery.destination else {
            return XCTFail("the code should be delivered by SMS")
        }
        XCTAssertNotNil(destination)
        let confirm = try await client.confirmSignIn(challengeResponse: code)
        XCTAssertEqual(Self.name(of: confirm.nextStep), "done")
    }

    /// MF-5: choosing TOTP when both types are enabled.
    ///
    /// - Given: a fresh user with a phone number, who enrolled TOTP through the client, enabled SMS and
    ///   TOTP with neither preferred, and signed out
    /// - When:
    ///    - the user signs in, selects `SOFTWARE_TOKEN_MFA`, then confirms with a code from the secret
    /// - Then:
    ///    - the sign-in offers `[.sms, .totp]`; the selection asks for the TOTP code; the confirmation is
    ///      `.done`
    ///
    func testSelectMFATypeWithTOTPWhileSigningIn() async throws {
        let (client, user) = try await signedInFreshUser("mf-5", withPhoneNumber: true)
        let secret = try await enrollTOTP(client, user)
        try await client.updateMFAPreference(sms: .enabled, totp: .enabled)
        try await client.signOut()

        let signIn = try await client.signIn(username: user.username, password: XCTUnwrap(user.password))

        guard case .continueSignInWithMFASelection(let offered) = signIn.nextStep else {
            return XCTFail("expected continueSignInWithMFASelection, got \(Self.name(of: signIn.nextStep))")
        }
        XCTAssertEqual(offered, [.sms, .totp])
        let selected = try await client.confirmSignIn(challengeResponse: AuthClientMFAType.totp.challengeResponse)
        guard case .confirmSignInWithTOTPCode = selected.nextStep else {
            return XCTFail("expected confirmSignInWithTOTPCode, got \(Self.name(of: selected.nextStep))")
        }
        let confirm = try await client.confirmSignIn(challengeResponse: TOTP.freshCode(secret: secret))
        XCTAssertEqual(Self.name(of: confirm.nextStep), "done")
    }

    /// MF-6: choosing SMS when both types are enabled.
    ///
    /// - Given: as MF-5, on U-PL
    /// - When:
    ///    - the user signs in, selects `SMS_MFA`, then confirms with the code the custom SMS sender captured
    /// - Then:
    ///    - the sign-in offers `[.sms, .totp]`; the selection asks for the SMS code with an SMS
    ///      destination; the confirmation is `.done`
    ///
    func testSelectMFATypeWithSMSWhileSigningIn() async throws {
        let (client, user) = try await signedInFreshUser("mf-6", on: .passwordless, withPhoneNumber: true)
        try await enrollTOTP(client, user)
        try await client.updateMFAPreference(sms: .enabled, totp: .enabled)
        try await client.signOut()
        let sink = try CodeSink()

        let signIn = try await client.signIn(username: user.username, password: XCTUnwrap(user.password))

        guard case .continueSignInWithMFASelection(let offered) = signIn.nextStep else {
            return XCTFail("expected continueSignInWithMFASelection, got \(Self.name(of: signIn.nextStep))")
        }
        XCTAssertEqual(offered, [.sms, .totp])
        let (selected, code) = try await sink.code(for: user, .mfa) {
            try await client.confirmSignIn(challengeResponse: AuthClientMFAType.sms.challengeResponse)
        }
        guard case .confirmSignInWithSMSMFACode(let delivery, _) = selected.nextStep else {
            return XCTFail("expected confirmSignInWithSMSMFACode, got \(Self.name(of: selected.nextStep))")
        }
        guard case .sms(let destination) = delivery.destination else {
            return XCTFail("the code should be delivered by SMS")
        }
        XCTAssertNotNil(destination)
        let confirm = try await client.confirmSignIn(challengeResponse: code)
        XCTAssertEqual(Self.name(of: confirm.nextStep), "done")
    }
}
