//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyCognitoClient
import XCTest

/// The plugin's `AuthUserAttributesTests`, through the client (AT-1 … AT-7), on
/// `default`: attribute updates need no verification first (`AttributesRequireVerificationBeforeUpdate`
/// is empty), and the custom senders put every code in the sink. The plugin's test names are kept.
///
/// AT-5 and AT-6 read a code and hold under either update setting, so they run on U-PL (`passwordless`),
/// whose outputs name a code API. AT-2 checks the email is updated before it is verified, which only a
/// backend with empty `AttributesRequireVerificationBeforeUpdate` shows: that is the default backend, as the
/// plugin's README sets it, so AT-2 stays there. As the plugin's test, it reads no code; its second half,
/// the code verifying the updated email (`testUpdatedEmailIsVerifiedWithTheCodeSentToIt`, not counted),
/// needs a code API on the default backend.
///
/// Every user is a fresh `ccit-` user signed in through the client, and deleted at teardown. No test prints
/// a username, email, password or code: the checks on them are boolean.
final class UserAttributesTests: ClientIntegrationTestCase {

    /// The client metadata the plugin's tests send.
    private let metadata = ["mydata": "myvalue"]

    /// Fetching returns the signed-up email (AT-1).
    ///
    /// - Given: a fresh user with an email, signed in
    /// - When:
    ///    - the client fetches the user's attributes
    /// - Then:
    ///    - the `email` attribute is the signed-up email
    ///
    func testSuccessfulFetchAttribute() async throws {
        let (client, user) = try await makeSignedInFreshUser("at-1")

        let attributes = try await client.fetchUserAttributes()

        let email = try XCTUnwrap(attributes.first { $0.key == .email }, "email attribute not found")
        XCTAssertTrue(email.value == user.email, "the email attribute is the signed-up email")
    }

    /// Updating the email sends a code to the new address, and the update is applied at once (AT-2), as
    /// far as the plugin's test goes: it stops at the update, and reads no code.
    ///
    /// - Given: a fresh user with an email, signed in
    /// - When:
    ///    - the client updates `email` to a new address, with client metadata
    /// - Then:
    ///    - the update is not complete: `.confirmAttributeWithCode` for `email`, by email
    ///    - fetching returns the new email, before it is verified
    ///
    func testSuccessfulUpdateEmailAttribute() async throws {
        let (client, _) = try await makeSignedInFreshUser("at-2")
        let updatedEmail = SandboxSignUp.identity().email

        let result = try await client.update(
            userAttribute: .init(.email, value: updatedEmail),
            options: .init(clientMetadata: metadata)
        )

        XCTAssertFalse(result.isUpdated)
        assertCodeSentToTheEmail(result.nextStep)
        let updated = try await client.fetchUserAttributes()
        XCTAssertTrue(updated.first { $0.key == .email }?.value == updatedEmail, "the email is the updated one")
    }

    /// The code sent for an updated email verifies it (AT-2's second half, not counted: the plugin's test
    /// stops at the update). On the default backend, where the update is applied before it is verified.
    ///
    /// It reads the code Cognito sends to the new address, so it needs a code API on the default backend.
    /// The plugin's CI file for it names none (its README deploys no custom senders): on CI it skips
    /// (`CISkipReason.defaultCodeAPI`), and elsewhere without one it fails naming the file.
    ///
    /// - Given: a fresh user with an email, signed in, on the default backend
    /// - When:
    ///    - the client updates `email` to a new address, with client metadata
    ///    - then confirms it with the first code the sink received after the update
    /// - Then:
    ///    - fetching returns the new email before the confirmation; after it, `email_verified` is `true`
    ///
    func testUpdatedEmailIsVerifiedWithTheCodeSentToIt() async throws {
        _ = try IntegrationTestEnvironment.codeSinkAPI(.standard, ciSkip: .defaultCodeAPI)
        let (client, user) = try await makeSignedInFreshUser("at-2-verify")
        let sink = try CodeSink()
        let updatedEmail = SandboxSignUp.identity().email

        let (result, code) = try await sink.code(for: user, .attributeVerification) {
            try await client.update(
                userAttribute: .init(.email, value: updatedEmail),
                options: .init(clientMetadata: metadata)
            )
        }

        XCTAssertFalse(result.isUpdated)
        let updated = try await client.fetchUserAttributes()
        XCTAssertTrue(updated.first { $0.key == .email }?.value == updatedEmail, "the email is the updated one")
        try await client.confirm(userAttribute: .email, confirmationCode: code)
        let confirmed = try await client.fetchUserAttributes()
        XCTAssertEqual(confirmed.first { $0.key == .emailVerified }?.value, "true")
    }

    /// Updating two attributes that need no verification completes both (AT-3).
    ///
    /// - Given: a fresh user, signed in
    /// - When:
    ///    - the client updates `family_name` and `name` in one call, with client metadata
    /// - Then:
    ///    - both are updated, `.done`
    ///    - fetching returns both new values
    ///
    func testSuccessfulUpdateOfMultipleAttributes() async throws {
        let (client, _) = try await makeSignedInFreshUser("at-3")
        let familyName = "Family\(UUID().uuidString.prefix(8))"
        let name = "Name\(UUID().uuidString.prefix(8))"

        let results = try await client.update(
            userAttributes: [.init(.familyName, value: familyName), .init(.name, value: name)],
            options: .init(clientMetadata: metadata)
        )

        XCTAssertEqual(results, [
            .familyName: AuthClientUpdateAttributeResult(isUpdated: true, nextStep: .done),
            .name: AuthClientUpdateAttributeResult(isUpdated: true, nextStep: .done)
        ])
        let attributes = try await client.fetchUserAttributes()
        XCTAssertEqual(attributes.first { $0.key == .familyName }?.value, familyName)
        XCTAssertEqual(attributes.first { $0.key == .name }?.value, name)
    }

    /// Confirming an updated email with a wrong code is `codeMismatch` (AT-4).
    ///
    /// - Given: a fresh user, signed in, whose email was just updated
    /// - When:
    ///    - the client confirms `email` with a code that was not sent
    /// - Then:
    ///    - it throws `.service(.codeMismatch)` (the plugin accepts any service error)
    ///
    func testSuccessfulUserAttributesConfirmation() async throws {
        let (client, _) = try await makeSignedInFreshUser("at-4")
        let result = try await client.update(
            userAttribute: .init(.email, value: SandboxSignUp.identity().email),
            options: .init(clientMetadata: metadata)
        )
        assertCodeSentToTheEmail(result.nextStep)

        do {
            try await client.confirm(userAttribute: .email, confirmationCode: "123")
            XCTFail("the attribute confirmation unexpectedly succeeded")
        } catch AuthClientError.service(.codeMismatch?, _, _, _) {
            return
        } catch {
            XCTFail("expected .service(.codeMismatch); got \(ClientErrorShape.of(error))")
        }
    }

    /// A new code can be sent for an updated email, and it is the one that verifies it (AT-5; the plugin's
    /// test stops at the send).
    ///
    /// - Given: a fresh user on U-PL, signed in, whose email was updated (which sent a first code)
    /// - When:
    ///    - the client sends a verification code for `email`, with client metadata
    ///    - then confirms `email` with the new code
    /// - Then:
    ///    - the code goes to the email, a new code reaches the sink, and it verifies the email
    ///
    func testSuccessfulSendVerificationCodeWithUpdatedEmail() async throws {
        let (client, user) = try await makeSignedInFreshUser("at-5", on: .passwordless)
        let sink = try CodeSink()
        _ = try await sink.code(for: user, .attributeVerification) {
            try await client.update(userAttribute: .init(.email, value: SandboxSignUp.identity().email))
        }

        let (details, code) = try await sink.code(for: user, .attributeVerification) {
            try await client.sendVerificationCode(forUserAttributeKey: .email, options: .init(clientMetadata: metadata))
        }

        XCTAssertEqual(details.attributeKey, .email)
        guard case .email = details.destination else {
            return XCTFail("expected the code to go to the email")
        }
        try await client.confirm(userAttribute: .email, confirmationCode: code)
        let attributes = try await client.fetchUserAttributes()
        XCTAssertEqual(attributes.first { $0.key == .emailVerified }?.value, "true")
    }

    /// A verification code can be sent for the signed-up email (AT-6).
    ///
    /// - Given: a fresh user with an email on U-PL, signed in
    /// - When:
    ///    - the client sends a verification code for `email`, with client metadata
    /// - Then:
    ///    - the code goes to the email, and reaches the sink
    ///
    func testSuccessfulSendVerificationCode() async throws {
        let (client, user) = try await makeSignedInFreshUser("at-6", on: .passwordless)
        let sink = try CodeSink()

        let (details, code) = try await sink.code(for: user, .attributeVerification) {
            try await client.sendVerificationCode(forUserAttributeKey: .email, options: .init(clientMetadata: metadata))
        }

        XCTAssertEqual(details.attributeKey, .email)
        guard case .email = details.destination else {
            return XCTFail("expected the code to go to the email")
        }
        XCTAssertFalse(code.isEmpty)
    }

    /// Changing the password keeps the user, and the new password signs in (AT-7).
    ///
    /// - Given: a fresh user, signed in
    /// - When:
    ///    - the client changes the password, fetches the attributes, signs out, and signs in with the new
    ///      password
    /// - Then:
    ///    - the email is unchanged; the sign-in is `.done` as the same user
    ///
    func testSuccessfulChangePassword() async throws {
        let (client, user) = try await makeSignedInFreshUser("at-7")
        let oldPassword = try XCTUnwrap(user.password)
        let newPassword = SandboxSignUp.freshPassword()

        try await client.update(oldPassword: oldPassword, to: newPassword)
        user.recordPassword(newPassword)

        let attributes = try await client.fetchUserAttributes()
        XCTAssertTrue(attributes.first { $0.key == .email }?.value == user.email, "the email is unchanged")
        XCTAssertSignOutComplete(await client.signOut())
        let signIn = try await client.signIn(username: user.username, password: newPassword)
        XCTAssertEqual(signIn.nextStep, .done)
        let signedIn = try await client.getCurrentUser()
        XCTAssertTrue(signedIn.username.lowercased() == user.username.lowercased(), "the new password signs the user in")
    }

    // MARK: Helpers

    /// `step` is `.confirmAttributeWithCode` for `email`, delivered by email.
    private func assertCodeSentToTheEmail(
        _ step: AuthClientUpdateAttributeStep,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard case .confirmAttributeWithCode(let details, _) = step else {
            return XCTFail("expected .confirmAttributeWithCode", file: file, line: line)
        }
        XCTAssertEqual(details.attributeKey, .email, file: file, line: line)
        guard case .email = details.destination else {
            return XCTFail("expected the code to go to the email", file: file, line: line)
        }
    }
}
