//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Shared with CognitoClientUITests (the hosted-UI UI tests), which compiles this file and the five other
// shared sandbox helpers (IntegrationTestEnvironment, SandboxPools, SandboxSignUp, SandboxUserCleanup,
// CodeSink, TOTP) and nothing else from this folder. Keep it self-contained: it may use only those files,
// AmplifyCognitoClient, AWSCognitoIdentityProvider, Foundation, Security, CryptoKit and XCTest.

import AWSCognitoIdentityProvider
import Foundation

/// Fresh users for the parity suites: a raw-SDK `SignUp` on a
/// parity pool's public app client, which needs no AWS credentials, mirroring the plugin's
/// `registerAndSignInUser`.
///
/// Every identity is test-shaped, which is also all the pools' pre-sign-up trigger accepts:
/// - the username is `ccit-<12 hex>`, or `ccit-confirm-<12 hex>` for a user the trigger leaves
///   unconfirmed, so a test reaches the confirm step; everyone else is auto-confirmed and auto-verified;
/// - the email is `<username>@example.com` (RFC 2606). On `email-alias` the email is the username;
/// - the phone number is fictional: `+1 555` and seven random digits.
///
/// A pool with no pre-sign-up trigger (the plugin's passwordless backend) leaves every sign-up unconfirmed:
/// a user the test wants confirmed is then confirmed with its sign-up code, so the rest of the test sees
/// the same user either way.
///
/// No message is ever delivered: the pools' custom senders hand every code to the code API. Delete each
/// user when the test ends (`XCTestCase.deleteAtTeardown(_:)`, or `ClientIntegrationTestCase.makeFreshUser`,
/// which does it for you); the sandbox's `prepare-run.sh` removes any left over after 24 hours (P-12).
enum SandboxSignUp {

    /// What a fresh user signs up with.
    struct Options: Sendable {
        /// Leave the user unconfirmed (`ccit-confirm-…`), so the test reaches the confirm step.
        var needsConfirmation = false
        /// Sign up with a password. `false` is a passwordless sign-up (U-PL, SU-8); the user then signs in
        /// with an OTP.
        var withPassword = true
        /// Add the `@example.com` email. Always added on `email-alias`, where it is the username.
        var withEmail = true
        /// Add a fictional `+1 555` phone number.
        var withPhoneNumber = false
        /// More attributes, such as `name`.
        var attributes: [String: String] = [:]

        init(
            needsConfirmation: Bool = false,
            withPassword: Bool = true,
            withEmail: Bool = true,
            withPhoneNumber: Bool = false,
            attributes: [String: String] = [:]
        ) {
            self.needsConfirmation = needsConfirmation
            self.withPassword = withPassword
            self.withEmail = withEmail
            self.withPhoneNumber = withPhoneNumber
            self.attributes = attributes
        }
    }

    /// Signs a fresh user up on `pool` with the raw SDK, and checks it is as asked: confirmed (by the
    /// pre-sign-up trigger, or else with its sign-up code), or left for the confirm step.
    static func signUp(on pool: SandboxPool, _ options: Options = Options()) async throws -> FreshUser {
        try await signUp(on: SandboxPools.pool(pool), options)
    }

    /// Signs a fresh user up through an existing pool client.
    static func signUp(on pool: SandboxPoolClient, _ options: Options = Options()) async throws -> FreshUser {
        // Before any request: a role that cannot confirm a user gets no sign-up, so no message either.
        try requireNotKnownUnconfirmable(pool.pool)
        let identity = identity(needsConfirmation: options.needsConfirmation)
        let email = options.withEmail || pool.pool.usesEmailAsUsername ? identity.email : nil
        let phoneNumber = options.withPhoneNumber ? fictionalPhoneNumber() : nil
        let password = options.withPassword ? identity.password : nil
        let username = pool.pool.usesEmailAsUsername ? identity.email : identity.username

        var attributes: [CognitoIdentityProviderClientTypes.AttributeType] = []
        if let email {
            attributes.append(.init(name: "email", value: email))
        }
        if let phoneNumber {
            attributes.append(.init(name: "phone_number", value: phoneNumber))
        }
        for (name, value) in options.attributes.sorted(by: { $0.key < $1.key }) {
            attributes.append(.init(name: name, value: value))
        }
        // Listening before the sign-up: its code, or any later one, is published once, when it is sent.
        await CodeSink.prepare(pool.pool)
        let signedUpAt = Date()
        let output = try await pool.client.signUp(input: SignUpInput(
            clientId: pool.clientId,
            password: password,
            userAttributes: attributes,
            username: username
        ))
        guard let userSub = output.userSub else {
            throw HarnessError.malformedFixture("SignUp returned no user sub.")
        }
        if output.userConfirmed, options.needsConfirmation {
            throw HarnessError.malformedFixture("""
            \(pool.pool.rawValue) confirmed a sign-up this test needs unconfirmed: the backend needs a \
            pre-sign-up trigger that leaves `\(confirmPrefix)` users for the confirm step.
            """)
        }
        let user = FreshUser(
            pool: pool.pool,
            username: username,
            password: password,
            email: email,
            phoneNumber: phoneNumber,
            userSub: userSub,
            isConfirmed: output.userConfirmed,
            signedUpAt: signedUpAt
        )
        if !output.userConfirmed, !options.needsConfirmation {
            // No pre-sign-up trigger confirmed it (the plugin's passwordless backend has none).
            try requireCodeAPIToConfirm(pool.pool)
            try await confirm(user, sentSince: signedUpAt, on: pool, sink: CodeSink())
        }
        return user
    }

    /// Fails, naming the file, when `pool` left a fresh sign-up unconfirmed and its outputs name no code
    /// API to confirm it with: then no test can have a confirmed fresh user there. A role known up front to
    /// be so (`cannotConfirmUpFront(_:)`) never gets this far; this is for a backend that did not do what its
    /// setup promises.
    ///
    /// The role is then remembered for the rest of the process (`requireNotKnownUnconfirmable(_:)`), so later
    /// tests on it fail before signing another user up, rather than leave one more unconfirmed user on a
    /// backend that is not this harness's.
    static func requireCodeAPIToConfirm(_ pool: SandboxPool) throws {
        guard (try? IntegrationTestEnvironment.codeSinkAPI(pool)) == nil else {
            return
        }
        unconfirmableRoles.insert(pool)
        throw HarnessError.malformedFixture("""
        \(pool.sourceName): the backend left a fresh sign-up unconfirmed (no pre-sign-up trigger confirms it), \
        and the file names no code API (a data block with a url and an api_key) to confirm it with its sign-up \
        code. A test that needs a confirmed user on this backend needs one of the two.
        """)
    }

    /// Whether `pool` is known, before any sign-up, not to be able to confirm a fresh user: its file is not
    /// the sandbox's (no sandbox mark, `IntegrationTestEnvironment.isSandbox`), it names no code API to
    /// confirm one with its sign-up code, and the plugin's setup for its backend promises no pre-sign-up
    /// trigger that confirms one (`SandboxPool.promisesConfirmingTrigger`). The plugin's device-alias backend
    /// on CI is such a role: a user signed up there is left unconfirmed, and so can be neither signed in
    /// nor deleted (the cleanup signs the user in to delete it), and each sign-up sends Cognito's own
    /// confirmation email, which counts against the account's daily email limit.
    static func cannotConfirmUpFront(_ pool: SandboxPool) -> Bool {
        IntegrationTestEnvironment.hasOutputs(pool)
            && !IntegrationTestEnvironment.isSandbox(pool)
            && (try? IntegrationTestEnvironment.codeSinkAPI(pool)) == nil
            && !pool.promisesConfirmingTrigger
    }

    /// Fails, naming the file, before any sign-up on a role that cannot confirm a fresh user: one known not
    /// to up front (`cannotConfirmUpFront(_:)`), or one an earlier sign-up in this process showed cannot
    /// (`requireCodeAPIToConfirm(_:)`). No `SignUp` is sent. Call it before every sign-up, one left for the
    /// confirm step too: that user could not be confirmed or deleted either.
    static func requireNotKnownUnconfirmable(_ pool: SandboxPool) throws {
        if cannotConfirmUpFront(pool) {
            throw HarnessError.malformedFixture("""
            \(pool.sourceName): the file names no code API (a data block with a url and an api_key) to confirm a \
            fresh sign-up with its sign-up code, it is not the sandbox's, and the plugin's setup for this backend \
            promises no pre-sign-up trigger that confirms one, so no user is signed up there (no SignUp is sent, \
            and no email). A test that needs a fresh user on this backend needs one of the two.
            """)
        }
        guard unconfirmableRoles.contains(pool) else {
            return
        }
        throw HarnessError.malformedFixture("""
        \(pool.sourceName): an earlier sign-up in this run came back unconfirmed, and the file names no code API \
        to confirm it with, so no further user is signed up there. A test that needs a confirmed user on this \
        backend needs a pre-sign-up trigger that confirms it, or a code API (a data block with a url and an \
        api_key).
        """)
    }

    /// The roles `requireCodeAPIToConfirm(_:)` found cannot confirm a fresh user, for this process.
    private static let unconfirmableRoles = RoleSet()

    /// A set of roles shared across the process's tests, behind a lock.
    private final class RoleSet: @unchecked Sendable {
        private let lock = NSLock()
        private var roles: Set<SandboxPool> = []

        func insert(_ role: SandboxPool) {
            lock.withLock { _ = roles.insert(role) }
        }

        func contains(_ role: SandboxPool) -> Bool {
            lock.withLock { roles.contains(role) }
        }
    }

    /// Confirms an unconfirmed user with the sign-up code from the code sink, sent at or after `since`.
    static func confirm(_ user: FreshUser, sentSince since: Date, on pool: SandboxPoolClient, sink: CodeSink) async throws {
        let code = try await sink.code(for: user, .signUp, since: since)
        _ = try await pool.client.confirmSignUp(input: ConfirmSignUpInput(
            clientId: pool.clientId,
            confirmationCode: code,
            username: user.username
        ))
        user.recordConfirmed()
    }

    // MARK: - Identities

    /// A username, password and email no test or earlier run has used. The password meets every parity
    /// pool's policy.
    static func identity(needsConfirmation: Bool = false) -> (username: String, password: String, email: String) {
        let hex = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(12).lowercased()
        let username = "\(needsConfirmation ? confirmPrefix : prefix)\(hex)"
        return (username, freshPassword(), "\(username)@\(emailDomain)")
    }

    /// The address a user signed up without an email gives when sign-in asks it to set up email MFA
    /// (`MFA_SETUP` with `EMAIL_OTP`): `<username>@example.com`, so the test and the cleanup's raw
    /// sign-in answer with the same one.
    static func setupEmail(for user: FreshUser) -> String {
        "\(user.username)@\(emailDomain)"
    }

    /// A password meeting every parity pool's policy (min 10, upper, lower, number, symbol).
    static func freshPassword() -> String {
        "Ccit-\(UUID().uuidString)-1!"
    }

    /// A fictional phone number: `+1 555` then seven random digits. Area code 555 is not assigned, and
    /// every SMS-enabled pool's custom sender captures the code, so nothing is ever sent.
    static func fictionalPhoneNumber() -> String {
        "+1555" + String(format: "%07d", Int.random(in: 0 ..< 10_000_000))
    }

    /// The prefix of every user the tests create; the pre-sign-up trigger refuses anything else.
    static let prefix = "ccit-"
    /// The prefix of a user the pre-sign-up trigger leaves unconfirmed.
    static let confirmPrefix = "ccit-confirm-"
    /// RFC 2606: never delivered to.
    static let emailDomain = "example.com"
}

/// A user a test signed up. Its password and TOTP secret stay out of every textual representation, and
/// so do its sub and generated username (identifiers).
///
/// The test records what it changes (`recordPassword(_:)` after a password change or reset,
/// `recordTOTPSecret(_:)` after enrolling TOTP), so the raw sign-in and the cleanup can still sign in as
/// the user.
final class FreshUser: @unchecked Sendable, CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    let pool: SandboxPool
    /// What the user signs in with: `ccit-…`, or the email on `email-alias`.
    let username: String
    let email: String?
    let phoneNumber: String?
    /// The user's `sub`. On `email-alias` it is also the username Cognito generated.
    let userSub: String
    /// When its sign-up was sent: its sign-up code, its first, is the one sent since then.
    let signedUpAt: Date

    private let lock = NSLock()
    private var currentPassword: String?
    private var currentTOTPSecret: TOTPSecret?
    private var confirmed: Bool
    private var deleted = false

    init(
        pool: SandboxPool,
        username: String,
        password: String?,
        email: String?,
        phoneNumber: String?,
        userSub: String,
        isConfirmed: Bool,
        signedUpAt: Date = Date()
    ) {
        self.pool = pool
        self.username = username
        self.currentPassword = password
        self.email = email
        self.phoneNumber = phoneNumber
        self.userSub = userSub
        self.confirmed = isConfirmed
        self.signedUpAt = signedUpAt
    }

    /// The user's current password; nil for a passwordless sign-up.
    var password: String? {
        lock.withLock { currentPassword }
    }

    /// The user's TOTP secret, once enrolled.
    var totpSecret: TOTPSecret? {
        lock.withLock { currentTOTPSecret }
    }

    /// Whether the user is confirmed.
    var isConfirmed: Bool {
        lock.withLock { confirmed }
    }

    /// The username the code sink stores the user's codes under: the username Cognito passes the custom
    /// sender, lower-cased. On `email-alias` that is the generated username, the `sub`, not the email.
    var sinkUsername: String {
        (pool.usesEmailAsUsername ? userSub : username).lowercased()
    }

    /// The user as a `TestUser`, with its current password, for the client under test.
    var testUser: TestUser {
        TestUser(username: username, password: password ?? "")
    }

    func recordPassword(_ password: String) {
        lock.withLock { currentPassword = password }
    }

    func recordTOTPSecret(_ secret: TOTPSecret) {
        lock.withLock { currentTOTPSecret = secret }
    }

    func recordConfirmed() {
        lock.withLock { confirmed = true }
    }

    /// Whether the user is known to be deleted, so cleanup skips it.
    var isDeleted: Bool {
        lock.withLock { deleted }
    }

    /// Call after the test deletes the user itself (`deleteUser()`), so cleanup does not try to sign in
    /// as it.
    func recordDeleted() {
        lock.withLock { deleted = true }
    }

    var description: String { username }
    var debugDescription: String { "FreshUser(\(username), \(pool))" }
    var customMirror: Mirror { Mirror(self, children: ["username": username, "pool": pool]) }
}
