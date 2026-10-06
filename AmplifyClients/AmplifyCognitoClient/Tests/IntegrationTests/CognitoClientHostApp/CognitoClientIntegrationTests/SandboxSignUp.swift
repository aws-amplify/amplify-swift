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

@_spi(AmplifyExperimental) import AmplifyCognitoClient
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
        try requireSelfSignUp(pool.pool)
        return try await signUpFreshIdentity(on: pool, options, mayReplace: true)
    }

    /// `signUp(on:_:)` after its checks, with an identity generated here. `mayReplace`: whether an earlier
    /// attempt's user this cannot adopt may be replaced by one more fresh identity (`resolveAcceptedSignUp`).
    private static func signUpFreshIdentity(
        on pool: SandboxPoolClient,
        _ options: Options,
        mayReplace: Bool
    ) async throws -> FreshUser {
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
        // The user as signed up, once its sub is known.
        func makeUser(userSub: String, isConfirmed: Bool) -> FreshUser {
            FreshUser(
                pool: pool.pool,
                username: username,
                password: password,
                email: email,
                phoneNumber: phoneNumber,
                userSub: userSub,
                isConfirmed: isConfirmed,
                signedUpAt: signedUpAt
            )
        }
        let userSub: String
        let userConfirmed: Bool
        do {
            let output = try await pool.client.signUp(input: SignUpInput(
                clientId: pool.clientId,
                password: password,
                userAttributes: attributes,
                username: username
            ))
            guard let sub = output.userSub else {
                throw HarnessError.malformedFixture("SignUp returned no user sub.")
            }
            (userSub, userConfirmed) = (sub, output.userConfirmed)
        } catch is UsernameExistsException {
            // The username was generated a moment ago, in this call, from a random UUID, so no one else holds
            // it: the SDK sent this `SignUp` again after a transport failure (`NSURLErrorTimedOut`,
            // `NSURLErrorNetworkConnectionLost`) that hid Cognito's answer, and its first attempt created the
            // user (CH-4). Never reached for a fixed user: those are never signed up here.
            let earlier = makeUser(userSub: "", isConfirmed: false)
            switch try await resolveAcceptedSignUp(
                earlier,
                needsConfirmation: options.needsConfirmation,
                on: pool
            ) {
            case .adopt(let sub, let afterConfirming):
                log(afterConfirming ? "confirmed, then adopted" : "adopted", on: pool.pool)
                (userSub, userConfirmed) = (sub, true)
            case .replace:
                try requireReplaceable(mayReplace, on: pool.pool)
                if discards(earlier) {
                    log("replaced", on: pool.pool)
                    await discard(earlier)
                } else {
                    log("replaced, and left for the cleanup of old test users (its codes are keyed by a sub this call never learned)", on: pool.pool)
                }
                return try await signUpFreshIdentity(on: pool, options, mayReplace: false)
            }
        } catch {
            throw selfSignUpRefusal(error, on: pool.pool)
        }
        if userConfirmed, options.needsConfirmation {
            throw HarnessError.malformedFixture("""
            \(pool.pool.rawValue) confirmed a sign-up this test needs unconfirmed: the backend needs a \
            pre-sign-up trigger that leaves `\(confirmPrefix)` users for the confirm step.
            """)
        }
        let user = makeUser(userSub: userSub, isConfirmed: userConfirmed)
        if !userConfirmed, !options.needsConfirmation {
            // No pre-sign-up trigger confirmed it (the plugin's passwordless backend has none).
            try requireCodeAPIToConfirm(pool.pool)
            try await confirm(user, sentSince: signedUpAt, on: pool, sink: CodeSink())
        }
        return user
    }

    // MARK: - A sign-up the SDK sent twice (CH-4)

    /// What `signUp(on:_:)` does with the user an earlier attempt of its `SignUp` created, when the SDK's
    /// retry of that `SignUp` came back `UsernameExistsException`.
    enum AcceptedSignUp: Equatable, Sendable {
        /// Use it: it signed in with the password this call generated, so it is the user this call created,
        /// confirmed, and its access token names this sub. `afterConfirming`: it was unconfirmed, and this call
        /// confirmed it with its sign-up code before the sign-in.
        case adopt(userSub: String, afterConfirming: Bool)
        /// Sign a new fresh identity up instead, once. The user is this call's, but its sub cannot be learned
        /// without changing the user: an MFA challenge or MFA setup stands before its tokens, it is left
        /// unconfirmed for the confirm step, it has no password, or (on `email-alias`, where the code sink is
        /// keyed by the sub) it cannot be confirmed. The harness has no administrator client (no AWS
        /// credentials, `SandboxPools`), so `AdminGetUser` is not an option.
        case replace
    }

    /// What a password sign-in as an earlier attempt's user found.
    enum AcceptedSignUpProbe: Equatable, Sendable {
        /// Tokens, whose access token names this sub.
        case signedIn(userSub: String)
        /// The password was accepted, and a challenge (MFA, MFA setup) stands before the tokens.
        case challenged
        /// `UserNotConfirmedException`.
        case unconfirmed
    }

    /// Decides what to do with `user`, which an earlier attempt of this call's `SignUp` created (CH-4), and
    /// checks it is this call's. Ownership is proven only by a `.signedIn` probe: tokens for the password this
    /// call generated. Neither `UserNotConfirmedException` nor the confirm proves it (Cognito may report an
    /// unconfirmed user before it checks the password, and a sign-up code proves only that the username was
    /// signed up since this call's `SignUp`), so an unconfirmed user is confirmed with its sign-up code (the
    /// existing confirm path, `confirm(_:sentSince:on:sink:)`) and adopted only if the probe after that signs
    /// in. A user that refuses the password fails the sign-up, and is neither used nor deleted.
    static func resolveAcceptedSignUp(
        _ user: FreshUser,
        needsConfirmation: Bool,
        on pool: SandboxPoolClient
    ) async throws -> AcceptedSignUp {
        guard user.password != nil else {
            // A passwordless user signs in only with a code, which would leave one in the sink before the
            // test's own: replaced.
            return .replace
        }
        let canConfirm = !needsConfirmation
            && !pool.pool.usesEmailAsUsername
            && (try? IntegrationTestEnvironment.codeSinkAPI(pool.pool)) != nil
        return try await resolveAcceptedSignUp(
            canConfirm: canConfirm,
            probe: {
                let found = try await probeAcceptedSignUp { try await pool.passwordSignIn(user) }
                if found != .unconfirmed {
                    // So that discarding it does not wait for a sign-up code that never comes.
                    user.recordConfirmed()
                }
                return found
            },
            confirm: { try await confirm(user, sentSince: user.signedUpAt, on: pool, sink: CodeSink()) }
        )
    }

    /// `resolveAcceptedSignUp(_:needsConfirmation:on:)`'s decision, over its two requests: `probe`, a password
    /// sign-in as the user (`probeAcceptedSignUp(_:)`), and `confirm`, its confirmation with the sign-up code,
    /// tried only when `canConfirm` and the user is unconfirmed, and followed by one more probe.
    static func resolveAcceptedSignUp(
        canConfirm: Bool,
        probe: () async throws -> AcceptedSignUpProbe,
        confirm: () async throws -> Void
    ) async throws -> AcceptedSignUp {
        switch try await probe() {
        case .signedIn(let userSub):
            return .adopt(userSub: userSub, afterConfirming: false)
        case .challenged:
            return .replace
        case .unconfirmed:
            guard canConfirm else {
                return .replace
            }
            try await confirm()
            // Only this sign-in proves the user is this call's; the confirm did not.
            guard case .signedIn(let userSub) = try await probe() else {
                return .replace
            }
            return .adopt(userSub: userSub, afterConfirming: true)
        }
    }

    /// Runs `signIn`, a password sign-in's first step as an earlier attempt's user, and says what it found.
    /// Cognito's refusal of the password (`NotAuthorizedException`, or `UserNotFoundException` where existence
    /// errors are on) fails with `notThisCallsUserMessage`.
    static func probeAcceptedSignUp(_ signIn: () async throws -> RawSignInStep) async throws -> AcceptedSignUpProbe {
        let step: RawSignInStep
        do {
            step = try await signIn()
        } catch is UserNotConfirmedException {
            return .unconfirmed
        } catch is NotAuthorizedException {
            throw HarnessError.malformedFixture(notThisCallsUserMessage)
        } catch is UserNotFoundException {
            throw HarnessError.malformedFixture(notThisCallsUserMessage)
        }
        guard let tokens = step.authenticationResult else {
            return .challenged
        }
        guard let accessToken = tokens.accessToken,
              let sub = try IntegrationTestEnvironment.jwtClaims(accessToken)["sub"] as? String, !sub.isEmpty else {
            throw HarnessError.malformedFixture("An earlier sign-up's user signed in, but its access token names no sub.")
        }
        return .signedIn(userSub: sub)
    }

    /// Why a sign-up fails when the fresh username it generated exists and refuses this call's password.
    static let notThisCallsUserMessage = """
    SignUp of a freshly generated username came back UsernameExistsException, and the user by that name refuses \
    the password this call generated for it: it is not the user this sign-up created, so it is neither used nor \
    deleted.
    """

    /// Fails, after a second fresh identity's `SignUp` also came back `UsernameExistsException` and could not be
    /// adopted (`mayReplace` false): the harness replaces an earlier attempt's user once per sign-up, no more.
    static func requireReplaceable(_ mayReplace: Bool, on pool: SandboxPool) throws {
        guard !mayReplace else {
            return
        }
        throw HarnessError.malformedFixture("""
        \(pool.rawValue): two fresh sign-ups in a row were sent twice by the SDK and could not be used \
        (UsernameExistsException on each retry); the network to Cognito is failing.
        """)
    }

    /// Whether `discard(_:)` is worth trying for an earlier attempt's user. Not on `email-alias` while its sub
    /// is unknown: there its codes are keyed by the sub, so confirming it or answering its MFA would only wait
    /// out the code timeouts (about 120 s) before failing. It is left for the cleanup of old test users (P-12).
    static func discards(_ user: FreshUser) -> Bool {
        !(user.pool.usesEmailAsUsername && user.userSub.isEmpty)
    }

    /// Logs, in one line naming only the role, what a sign-up did with the user an earlier attempt of its
    /// `SignUp` created.
    private static func log(_ decision: String, on pool: SandboxPool) {
        print("[SandboxSignUp] \(pool.rawValue): the SDK retried an accepted SignUp (UsernameExistsException); the earlier attempt's user was \(decision).")
    }

    /// Deletes an earlier attempt's user this call did not adopt, best effort, through its own sign-in
    /// (`SandboxUserCleanup.delete(_:sink:)`), which only a user that accepts this call's credentials passes.
    /// One that cannot be deleted is left for the backend's cleanup of old test users (P-12); the line logged
    /// names its role only.
    private static func discard(_ user: FreshUser) async {
        do {
            try await SandboxUserCleanup.delete(user)
        } catch {
            print("[SandboxSignUp] left an earlier attempt's \(user.pool.rawValue) user for the cleanup of old test users (\(type(of: error))).")
        }
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
    /// confirm one with its sign-up code, and neither the plugin's setup for its backend nor its file promises a
    /// pre-sign-up trigger that confirms one (`IntegrationTestEnvironment.promisesConfirmingTrigger(_:)`). The plugin's device-alias backend
    /// on CI is such a role: a user signed up there is left unconfirmed, and so can be neither signed in
    /// nor deleted (the cleanup signs the user in to delete it), and each sign-up sends Cognito's own
    /// confirmation email, which counts against the account's daily email limit.
    static func cannotConfirmUpFront(_ pool: SandboxPool) -> Bool {
        IntegrationTestEnvironment.hasOutputs(pool)
            && !IntegrationTestEnvironment.isSandbox(pool)
            && (try? IntegrationTestEnvironment.codeSinkAPI(pool)) == nil
            && !IntegrationTestEnvironment.promisesConfirmingTrigger(pool)
    }

    /// Fails, naming the file, before any sign-up on a role that cannot confirm a fresh user: one known not
    /// to up front (`cannotConfirmUpFront(_:)`), or one an earlier sign-up in this process showed cannot
    /// (`requireCodeAPIToConfirm(_:)`). No `SignUp` is sent. Call it before every sign-up, one left for the
    /// confirm step too: that user could not be confirmed or deleted either.
    ///
    /// On CI, the device-alias role skips instead (`ciSkip(for:)`), with no `SignUp` sent either.
    static func requireNotKnownUnconfirmable(_ pool: SandboxPool) throws {
        if let skip = ciSkip(for: pool) {
            try IntegrationTestEnvironment.skipOnCIIfMissing(skip.reason, present: skip.present)
        }
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

    /// The CI skip a sign-up on `pool` takes, and whether what it needs is there: on the device-alias role,
    /// a way to confirm a fresh sign-up (`cannotConfirmUpFront(_:)`), which the plugin's device-alias backend on CI
    /// lacks. Nil for every other role, which fails as before when it cannot confirm one.
    static func ciSkip(for pool: SandboxPool) -> (reason: CISkipReason, present: Bool)? {
        guard pool == .emailAlias else {
            return nil
        }
        return (.deviceAliasConfirmation, !cannotConfirmUpFront(pool))
    }

    /// The roles `requireCodeAPIToConfirm(_:)` found cannot confirm a fresh user, for this process.
    private static let unconfirmableRoles = RoleSet()

    // MARK: - Self sign-up

    /// What `infra/self-sign-up.sh on -- <command>` sets to `on` for its run. `xcodebuild` passes it to the test
    /// runner as `TEST_RUNNER_COGNITO_CLIENT_INTEG_SELF_SIGN_UP`, which the script sets too.
    static let selfSignUpVariable = "COGNITO_CLIENT_INTEG_SELF_SIGN_UP"

    /// Why a sign-up on the sandbox fails fast while its self sign-up is off, its resting state.
    static let selfSignUpOffMessage = """
    Self sign-up is off on the sandbox. Run the suite through infra/self-sign-up.sh on -- <command>.
    """

    /// Fails, before any request, a sign-up on a sandbox role (`IntegrationTestEnvironment.isSandbox(_:)`) while
    /// the sandbox's self sign-up is off: outside an `infra/self-sign-up.sh` run, or after Cognito refused an
    /// earlier sign-up on the role in this process (`selfSignUpRefusal(_:on:)`). No `SignUp` is sent. A role
    /// that is not the sandbox's (the plugin's backends, on CI) is never checked: it allows self sign-up, and the
    /// script never runs there. Call it before every sign-up.
    static func requireSelfSignUp(_ pool: SandboxPool) throws {
        guard IntegrationTestEnvironment.isSandbox(pool) else {
            return
        }
        guard isInSelfSignUpRun else {
            throw HarnessError.malformedFixture("\(pool.sourceName): \(selfSignUpOffMessage)")
        }
        guard !selfSignUpOffRoles.contains(pool) else {
            throw HarnessError.malformedFixture("\(pool.sourceName): \(selfSignUpTurnedOffMessage)")
        }
    }

    /// Whether this process runs inside `infra/self-sign-up.sh on -- <command>`.
    static var isInSelfSignUpRun: Bool {
        ProcessInfo.processInfo.environment[selfSignUpVariable] == "on"
    }

    /// Why a sign-up fails inside an `infra/self-sign-up.sh` run that had turned self sign-up on: something
    /// turned it off again during the run.
    static let selfSignUpTurnedOffMessage = """
    Self sign-up was turned off on the sandbox during this infra/self-sign-up.sh run, which had turned it on \
    (Cognito refused the sign-up: SignUp is not permitted). An automated mitigation, another run's \
    `infra/self-sign-up.sh off --force`, or a change by hand may have done it. Check the account's security \
    findings, then run the suite again.
    """

    /// The backstop behind `requireSelfSignUp(_:)`: Cognito's refusal of a sign-up on a sandbox role whose self
    /// sign-up is off (`NotAuthorizedException`, "SignUp is not permitted", raw or through the client) becomes
    /// the same message, and the role is remembered for the rest of the process, as `unconfirmableRoles` are, so
    /// later tests on it fail before signing up. Any other error, or any error on a role that is not the
    /// sandbox's, is returned unchanged.
    static func selfSignUpRefusal(_ error: Error, on pool: SandboxPool) -> Error {
        let message: String? = switch error {
        case let refused as NotAuthorizedException: refused.message
        case AuthClientError.notAuthorized(let description, _, _): description
        default: nil
        }
        guard isSelfSignUpRefusal(message), IntegrationTestEnvironment.isSandbox(pool) else {
            return error
        }
        selfSignUpOffRoles.insert(pool)
        // Inside a run, the run had turned it on: say it was turned off since, not "run it through the script".
        if isInSelfSignUpRun {
            return HarnessError.malformedFixture("\(pool.sourceName): \(selfSignUpTurnedOffMessage)")
        }
        return HarnessError.malformedFixture("""
        \(pool.sourceName): \(selfSignUpOffMessage) (Cognito refused the sign-up: SignUp is not permitted.)
        """)
    }

    /// Whether a Cognito message is its refusal of a sign-up on a pool that does not allow self sign-up.
    static func isSelfSignUpRefusal(_ message: String?) -> Bool {
        message?.contains("SignUp is not permitted") == true
    }

    /// The roles Cognito refused a sign-up on in this process because self sign-up is off.
    private static let selfSignUpOffRoles = RoleSet()

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
