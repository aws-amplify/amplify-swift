//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyCognitoClient
import XCTest

/// Parity MF-7 … MF-12: the plugin's `MFAPreferenceTests`, with their
/// names and steps, on U-DEF through the client. Users that need SMS get a fictional `+1 555` number; the
/// custom SMS sender means no message is ever sent.
final class MFAPreferenceTests: ClientMFATestCase {

    private func assertPreference(
        _ client: AmplifyCognitoClient,
        enabled: Set<AuthClientMFAType>?,
        preferred: AuthClientMFAType?,
        _ step: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws {
        let preference = try await client.fetchMFAPreference()
        XCTAssertEqual(preference.enabled, enabled, step, file: file, line: line)
        XCTAssertEqual(preference.preferred, preferred, step, file: file, line: line)
    }

    /// MF-7: a new user has no MFA preference.
    ///
    /// - Given: a fresh user signed in through the client
    /// - When:
    ///    - `fetchMFAPreference()`
    /// - Then:
    ///    - `enabled` and `preferred` are both `nil`
    ///
    func testFetchEmptyMFAPreference() async throws {
        let (client, _) = try await signedInFreshUser("mf-7")

        try await assertPreference(client, enabled: nil, preferred: nil, "a new user")
    }

    /// MF-8: TOTP enabled, preferred, not preferred, then disabled.
    ///
    /// - Given: a fresh user signed in through the client, who enrolls TOTP
    /// - When:
    ///    - TOTP is updated to `.enabled`, `.preferred`, `.notPreferred` and `.disabled`, fetching after each
    /// - Then:
    ///    - the fetches read `[.totp]`/none, `[.totp]`/`.totp`, `[.totp]`/none, and none/none
    ///
    func testFetchAndUpdateMFAPreferenceForTOTP() async throws {
        let (client, user) = try await signedInFreshUser("mf-8")
        try await assertPreference(client, enabled: nil, preferred: nil, "before the setup")
        try await enrollTOTP(client, user)

        try await client.updateMFAPreference(sms: nil, totp: .enabled)
        try await assertPreference(client, enabled: [.totp], preferred: nil, "TOTP enabled")

        try await client.updateMFAPreference(sms: nil, totp: .preferred)
        try await assertPreference(client, enabled: [.totp], preferred: .totp, "TOTP preferred")

        try await client.updateMFAPreference(sms: nil, totp: .notPreferred)
        try await assertPreference(client, enabled: [.totp], preferred: nil, "TOTP not preferred")

        try await client.updateMFAPreference(sms: nil, totp: .disabled)
        try await assertPreference(client, enabled: nil, preferred: nil, "TOTP disabled")
    }

    /// MF-9: SMS enabled, preferred, not preferred, then disabled.
    ///
    /// - Given: a fresh user with a phone number, signed in through the client
    /// - When:
    ///    - SMS is updated to `.enabled`, `.preferred`, `.notPreferred` and `.disabled`, fetching after each
    /// - Then:
    ///    - the fetches read `[.sms]`/none, `[.sms]`/`.sms`, `[.sms]`/none, and none/none
    ///
    func testFetchAndUpdateMFAPreferenceForSMS() async throws {
        let (client, _) = try await signedInFreshUser("mf-9", withPhoneNumber: true)
        try await assertPreference(client, enabled: nil, preferred: nil, "a new user")

        try await client.updateMFAPreference(sms: .enabled, totp: nil)
        try await assertPreference(client, enabled: [.sms], preferred: nil, "SMS enabled")

        try await client.updateMFAPreference(sms: .preferred, totp: nil)
        try await assertPreference(client, enabled: [.sms], preferred: .sms, "SMS preferred")

        try await client.updateMFAPreference(sms: .notPreferred, totp: nil)
        try await assertPreference(client, enabled: [.sms], preferred: nil, "SMS not preferred")

        try await client.updateMFAPreference(sms: .disabled, totp: nil)
        try await assertPreference(client, enabled: nil, preferred: nil, "SMS disabled")
    }

    /// MF-10: SMS and TOTP together.
    ///
    /// - Given: a fresh user with a phone number, signed in through the client, who enrolls TOTP
    /// - When:
    ///    - both enabled; SMS preferred; SMS not preferred with TOTP preferred; SMS disabled; SMS preferred
    ///      again, fetching after each
    /// - Then:
    ///    - `[.sms, .totp]`/none; `[.sms, .totp]`/`.sms`; `[.sms, .totp]`/`.totp`; `[.totp]`/`.totp`; and
    ///      `[.sms, .totp]`/`.sms` (preferring SMS takes the preference from TOTP)
    ///
    func testFetchAndUpdateMFAPreferenceForSMSAndTOTP() async throws {
        let (client, user) = try await signedInFreshUser("mf-10", withPhoneNumber: true)
        try await assertPreference(client, enabled: nil, preferred: nil, "a new user")
        try await enrollTOTP(client, user)

        try await client.updateMFAPreference(sms: .enabled, totp: .enabled)
        try await assertPreference(client, enabled: [.sms, .totp], preferred: nil, "both enabled")

        try await client.updateMFAPreference(sms: .preferred, totp: .enabled)
        try await assertPreference(client, enabled: [.sms, .totp], preferred: .sms, "SMS preferred")

        try await client.updateMFAPreference(sms: .notPreferred, totp: .preferred)
        try await assertPreference(client, enabled: [.sms, .totp], preferred: .totp, "TOTP preferred")

        try await client.updateMFAPreference(sms: .disabled, totp: nil)
        try await assertPreference(client, enabled: [.totp], preferred: .totp, "SMS disabled")

        try await client.updateMFAPreference(sms: .preferred, totp: nil)
        try await assertPreference(client, enabled: [.sms, .totp], preferred: .sms, "SMS preferred again")
    }

    /// MF-11: two preferred types are refused.
    ///
    /// - Given: a fresh user with a phone number, signed in through the client, who enrolls TOTP
    /// - When:
    ///    - SMS and TOTP are both updated to `.preferred`
    /// - Then:
    ///    - it throws `.service(.invalidParameter, …)`: only one type can be preferred
    ///
    func testSMSAndTOTPMarkedAsPreferred() async throws {
        let (client, user) = try await signedInFreshUser("mf-11", withPhoneNumber: true)
        try await enrollTOTP(client, user)

        do {
            try await client.updateMFAPreference(sms: .preferred, totp: .preferred)
            XCTFail("two types cannot both be preferred")
        } catch {
            guard case .service(.invalidParameter?, _, _, _) = error as? AuthClientError else {
                return XCTFail("expected .service(.invalidParameter), got \(Self.describe(error))")
            }
        }
    }

    /// MF-12: `.enabled` keeps the preferred type preferred.
    ///
    /// - Given: a fresh user with a phone number, signed in through the client, who enrolls TOTP
    /// - When:
    ///    - SMS preferred with TOTP enabled; then both updated to `.enabled`
    /// - Then:
    ///    - both fetches read `[.sms, .totp]`/`.sms`
    ///
    func testFetchAndUpdateMFAPreferenceForAlreadyPreferredMethod() async throws {
        let (client, user) = try await signedInFreshUser("mf-12", withPhoneNumber: true)
        try await assertPreference(client, enabled: nil, preferred: nil, "a new user")
        try await enrollTOTP(client, user)

        try await client.updateMFAPreference(sms: .preferred, totp: .enabled)
        try await assertPreference(client, enabled: [.sms, .totp], preferred: .sms, "SMS preferred")

        try await client.updateMFAPreference(sms: .enabled, totp: .enabled)
        try await assertPreference(client, enabled: [.sms, .totp], preferred: .sms, "both enabled again")
    }
}
