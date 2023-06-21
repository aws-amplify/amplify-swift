//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import AWSCognitoAuthPlugin

class TOTPPreferenceTests: AWSAuthBaseTest {

    override func setUp() async throws {
        try await super.setUp()
        AuthSessionHelper.clearSession()
    }

    override func tearDown() async throws {
        // Clean up user
        try await Amplify.Auth.deleteUser()
        try await super.tearDown()
        AuthSessionHelper.clearSession()
    }

    func signUpAndSignIn(phoneNumber: String? = nil) async throws {
        let username = "integTest\(UUID().uuidString)"
        let password = "P123@\(UUID().uuidString)"

        let didSucceed = try await AuthSignInHelper.registerAndSignInUser(
            username: username,
            password: password,
            email: defaultTestEmail,
            phoneNumber: phoneNumber)

        XCTAssertTrue(didSucceed, "Signup and sign in should succeed")
    }

    /// Test successful call to fetchMFAPreference API
    ///
    /// - Given: A newly signed up user in Cognito user pool
    /// - When:
    ///    - I invoke fetchMFAPreference API
    /// - Then:
    ///    - I should get empty preference results
    ///
    func testFetchEmptyMFAPreference() async throws {
        do {
            try await signUpAndSignIn()

            let authCognitoPlugin = try Amplify.Auth.getPlugin(
                for: "awsCognitoAuthPlugin") as! AWSCognitoAuthPlugin

            let fetchMFAResult = try await authCognitoPlugin.fetchMFAPreference()
            XCTAssertNil(fetchMFAResult.enabled)
            XCTAssertNil(fetchMFAResult.preferred)
        } catch {
            XCTFail("API should succeed without any errors instead failed with \(error)")
        }
    }

    /// Test successful call to fetchMFAPreference and updateMFAPreference API for TOTP
    ///
    /// - Given: A newly signed up user in Cognito user pool
    /// - When:
    ///    - I invoke fetchMFAPreference and updateMFAPreference API under various conditions
    /// - Then:
    ///    - I should get valid fetchMFAPreference results corresponding to the updateMFAPreference
    ///
    func testFetchAndUpdateMFAPreferenceForTOTP() async throws {
        do {
            try await signUpAndSignIn()

            let authCognitoPlugin = try Amplify.Auth.getPlugin(
                for: "awsCognitoAuthPlugin") as! AWSCognitoAuthPlugin

            var fetchMFAResult = try await authCognitoPlugin.fetchMFAPreference()
            XCTAssertNil(fetchMFAResult.enabled)
            XCTAssertNil(fetchMFAResult.preferred)

            let totpSetupDetails = try await Amplify.Auth.setUpTOTP()
            let totpCode = TOTPHelper.generateTOTPCode(sharedSecret: totpSetupDetails.sharedSecret)
            try await Amplify.Auth.verifyTOTPSetup(code: totpCode)

            // Test enabled
            try await authCognitoPlugin.updateMFAPreference(
                sms: nil,
                totp: .enabled)

            fetchMFAResult = try await authCognitoPlugin.fetchMFAPreference()
            XCTAssertNotNil(fetchMFAResult.enabled)
            XCTAssertEqual(fetchMFAResult.enabled, [.totp])
            XCTAssertNil(fetchMFAResult.preferred)

            // Test preferred
            try await authCognitoPlugin.updateMFAPreference(
                sms: nil,
                totp: .preferred)

            fetchMFAResult = try await authCognitoPlugin.fetchMFAPreference()
            XCTAssertNotNil(fetchMFAResult.enabled)
            XCTAssertEqual(fetchMFAResult.enabled, [.totp])
            XCTAssertNotNil(fetchMFAResult.preferred)
            XCTAssertEqual(fetchMFAResult.preferred, .totp)

            // Test notPreferred
            try await authCognitoPlugin.updateMFAPreference(
                sms: nil,
                totp: .notPreferred)

            fetchMFAResult = try await authCognitoPlugin.fetchMFAPreference()
            XCTAssertNotNil(fetchMFAResult.enabled)
            XCTAssertEqual(fetchMFAResult.enabled, [.totp])
            XCTAssertNil(fetchMFAResult.preferred)

            // Test disabled
            try await authCognitoPlugin.updateMFAPreference(
                sms: nil,
                totp: .disabled)

            fetchMFAResult = try await authCognitoPlugin.fetchMFAPreference()
            XCTAssertNil(fetchMFAResult.enabled)
            XCTAssertNil(fetchMFAResult.preferred)
        } catch {
            XCTFail("API should succeed without any errors instead failed with \(error)")
        }
    }

    /// Test successful call to fetchMFAPreference and updateMFAPreference API for SMS
    ///
    /// - Given: A newly signed up user in Cognito user pool
    /// - When:
    ///    - I invoke fetchMFAPreference and updateMFAPreference API under various conditions
    /// - Then:
    ///    - I should get valid fetchMFAPreference results corresponding to the updateMFAPreference
    ///
    func testFetchAndUpdateMFAPreferenceForSMS() async throws {
        do {
            try await signUpAndSignIn(phoneNumber: "+16135550116") // Fake number for testing

            let authCognitoPlugin = try Amplify.Auth.getPlugin(
                for: "awsCognitoAuthPlugin") as! AWSCognitoAuthPlugin

            var fetchMFAResult = try await authCognitoPlugin.fetchMFAPreference()
            XCTAssertNil(fetchMFAResult.enabled)
            XCTAssertNil(fetchMFAResult.preferred)

            // Test enabled
            try await authCognitoPlugin.updateMFAPreference(
                sms: .enabled,
                totp: nil)

            fetchMFAResult = try await authCognitoPlugin.fetchMFAPreference()
            XCTAssertNotNil(fetchMFAResult.enabled)
            XCTAssertEqual(fetchMFAResult.enabled, [.sms])
            XCTAssertNil(fetchMFAResult.preferred)

            // Test preferred
            try await authCognitoPlugin.updateMFAPreference(
                sms: .preferred,
                totp: nil)

            fetchMFAResult = try await authCognitoPlugin.fetchMFAPreference()
            XCTAssertNotNil(fetchMFAResult.enabled)
            XCTAssertEqual(fetchMFAResult.enabled, [.sms])
            XCTAssertNotNil(fetchMFAResult.preferred)
            XCTAssertEqual(fetchMFAResult.preferred, .sms)

            // Test notPreferred
            try await authCognitoPlugin.updateMFAPreference(
                sms: .notPreferred,
                totp: nil)

            fetchMFAResult = try await authCognitoPlugin.fetchMFAPreference()
            XCTAssertNotNil(fetchMFAResult.enabled)
            XCTAssertEqual(fetchMFAResult.enabled, [.sms])
            XCTAssertNil(fetchMFAResult.preferred)

            // Test disabled
            try await authCognitoPlugin.updateMFAPreference(
                sms: .disabled,
                totp: nil)

            fetchMFAResult = try await authCognitoPlugin.fetchMFAPreference()
            XCTAssertNil(fetchMFAResult.enabled)
            XCTAssertNil(fetchMFAResult.preferred)
        } catch {
            XCTFail("API should succeed without any errors instead failed with \(error)")
        }
    }

    /// Test successful call to fetchMFAPreference and updateMFAPreference API for SMS and TOTP
    ///
    /// - Given: A newly signed up user in Cognito user pool
    /// - When:
    ///    - I invoke fetchMFAPreference and updateMFAPreference API under various conditions
    /// - Then:
    ///    - I should get valid fetchMFAPreference results corresponding to the updateMFAPreference
    ///
    func testFetchAndUpdateMFAPreferenceForSMSAndTOTP() async throws {
        do {
            try await signUpAndSignIn(phoneNumber: "+16135550116") // Fake number for testing

            let authCognitoPlugin = try Amplify.Auth.getPlugin(
                for: "awsCognitoAuthPlugin") as! AWSCognitoAuthPlugin

            var fetchMFAResult = try await authCognitoPlugin.fetchMFAPreference()
            XCTAssertNil(fetchMFAResult.enabled)
            XCTAssertNil(fetchMFAResult.preferred)

            let totpSetupDetails = try await Amplify.Auth.setUpTOTP()
            let totpCode = TOTPHelper.generateTOTPCode(sharedSecret: totpSetupDetails.sharedSecret)
            try await Amplify.Auth.verifyTOTPSetup(code: totpCode)

            // Test both MFA types as enabled
            try await authCognitoPlugin.updateMFAPreference(
                sms: .enabled,
                totp: .enabled)

            fetchMFAResult = try await authCognitoPlugin.fetchMFAPreference()
            XCTAssertNotNil(fetchMFAResult.enabled)
            XCTAssertEqual(fetchMFAResult.enabled, [.sms, .totp])
            XCTAssertNil(fetchMFAResult.preferred)

            // Test SMS as preferred, TOTP as enabled
            try await authCognitoPlugin.updateMFAPreference(
                sms: .preferred,
                totp: .enabled)

            fetchMFAResult = try await authCognitoPlugin.fetchMFAPreference()
            XCTAssertNotNil(fetchMFAResult.enabled)
            XCTAssertEqual(fetchMFAResult.enabled, [.sms, .totp])
            XCTAssertNotNil(fetchMFAResult.preferred)
            XCTAssertEqual(fetchMFAResult.preferred, .sms)

            // Test SMS as notPreferred, TOTP as preferred
            try await authCognitoPlugin.updateMFAPreference(
                sms: .notPreferred,
                totp: .preferred)

            fetchMFAResult = try await authCognitoPlugin.fetchMFAPreference()
            XCTAssertNotNil(fetchMFAResult.enabled)
            XCTAssertEqual(fetchMFAResult.enabled, [.sms, .totp])
            XCTAssertNotNil(fetchMFAResult.preferred)
            XCTAssertEqual(fetchMFAResult.preferred, .totp)

            // Test SMS as disabled, no change to TOTP
            try await authCognitoPlugin.updateMFAPreference(
                sms: .disabled,
                totp: nil)

            fetchMFAResult = try await authCognitoPlugin.fetchMFAPreference()
            XCTAssertNotNil(fetchMFAResult.enabled)
            XCTAssertEqual(fetchMFAResult.enabled, [.totp])
            XCTAssertNotNil(fetchMFAResult.preferred)
            XCTAssertEqual(fetchMFAResult.preferred, .totp)

            // Test SMS as preferred, no change to TOTP (which should remove TOTP from preferred list)
            try await authCognitoPlugin.updateMFAPreference(
                sms: .preferred,
                totp: nil)

            fetchMFAResult = try await authCognitoPlugin.fetchMFAPreference()
            XCTAssertNotNil(fetchMFAResult.enabled)
            XCTAssertEqual(fetchMFAResult.enabled, [.sms, .totp])
            XCTAssertNotNil(fetchMFAResult.preferred)
            XCTAssertEqual(fetchMFAResult.preferred, .sms)
        } catch {
            XCTFail("API should succeed without any errors instead failed with \(error)")
        }
    }

    /// Test invalidParameter exception in updateMFAPreference API
    ///
    /// - Given: A newly signed up user in Cognito user pool
    /// - When:
    ///    - I invoke updateMFAPreference API with both MFA types as preferred
    /// - Then:
    ///    - I should get an invalid parameter exception as only one MFA method can be set to preferred
    ///
    func testSMSAndTOTPMarkedAsPreferred() async throws {
        do {
            try await signUpAndSignIn(phoneNumber: "+16135550116") // Fake number for testing

            let authCognitoPlugin = try Amplify.Auth.getPlugin(
                for: "awsCognitoAuthPlugin") as! AWSCognitoAuthPlugin

            let totpSetupDetails = try await Amplify.Auth.setUpTOTP()
            let totpCode = TOTPHelper.generateTOTPCode(sharedSecret: totpSetupDetails.sharedSecret)
            try await Amplify.Auth.verifyTOTPSetup(code: totpCode)

            // Test both MFA types as enabled
            try await authCognitoPlugin.updateMFAPreference(
                sms: .preferred,
                totp: .preferred)

            XCTFail("Should not proceed, because MFA types cannot be marked as preferred")
        } catch {
            guard let authError = error as? AuthError,
                  case .service(_, _, let underlyingError) = authError else {
                XCTFail("Should throw service error")
                return
            }
            guard case .invalidParameter = underlyingError as? AWSCognitoAuthError else {
                XCTFail("Should throw invalidParameter error.")
                return
            }
        }
    }

}
