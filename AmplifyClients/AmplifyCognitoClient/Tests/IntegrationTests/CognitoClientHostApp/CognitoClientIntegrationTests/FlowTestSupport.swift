//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
@_spi(AmplifyExperimental) import AmplifyFoundation
import AWSCognitoIdentity
import AWSCognitoIdentityProvider
import CryptoKit
import Foundation
import XCTest

/// Collects every element of a session's state or event stream, from the moment it is created.
///
/// Subscribe before the operation under test: the streams do not replay. `waitUntil` bounds a wait for
/// an element that is already on its way; `waitUntilFinished` returns everything the stream delivered
/// once the session is released (the streams finish when the last handle and provider go away), which
/// is how a test proves an event came *exactly* once. The bounds only stop a leaked handle from hanging
/// the run; nothing asserts on how long a wait takes.
///
/// Waiters suspend on a continuation that the next element (or the stream's end, or the deadline) resumes;
/// nothing polls. The collecting task holds the recorder weakly, so dropping the recorder cancels it.
final class StreamRecorder<Element: Sendable>: @unchecked Sendable {

    private let lock = NSLock()
    private var collected: [Element] = []
    private var finished = false
    /// Moves on every element and on the stream's end, so a waiter can tell a change it has not seen.
    private var version = 0
    private var waiters: [UUID: CheckedContinuation<Void, Never>] = [:]
    /// Waits whose deadline passed before they registered.
    private var timedOut: Set<UUID> = []
    private var task: Task<Void, Never>?

    init(_ stream: AsyncStream<Element>) {
        self.task = Task { [weak self] in
            for await element in stream {
                guard let self else {
                    return
                }
                change { $0.collected.append(element) }
            }
            self?.change { $0.finished = true }
        }
    }

    deinit {
        task?.cancel()
    }

    /// Everything delivered so far.
    var elements: [Element] {
        lock.withLock { collected }
    }

    /// Waits until `predicate` holds for the elements delivered so far, and returns them.
    @discardableResult
    func waitUntil(
        _ what: String,
        timeout: TimeInterval = 10,
        _ predicate: ([Element]) -> Bool
    ) async throws -> [Element] {
        let deadline = Date().addingTimeInterval(timeout)
        while true {
            let (elements, isFinished, seen) = lock.withLock { (collected, finished, version) }
            if predicate(elements) {
                return elements
            }
            guard !isFinished, Date() < deadline else {
                // The count only: elements can carry a user's sub.
                throw HarnessError.timedOut("\(what); the stream delivered \(elements.count) elements")
            }
            await nextChange(after: seen, deadline: deadline)
        }
    }

    /// Waits until the stream finishes, and returns everything it delivered.
    func waitUntilFinished(timeout: TimeInterval = 10) async throws -> [Element] {
        let deadline = Date().addingTimeInterval(timeout)
        while true {
            let (elements, isFinished, seen) = lock.withLock { (collected, finished, version) }
            if isFinished {
                return elements
            }
            guard Date() < deadline else {
                throw HarnessError.timedOut("the stream to finish; is a handle on the session still held?")
            }
            await nextChange(after: seen, deadline: deadline)
        }
    }

    /// Applies `update` under the lock, moves the version, and wakes every waiter.
    private func change(_ update: (StreamRecorder) -> Void) {
        let woken: [CheckedContinuation<Void, Never>] = lock.withLock {
            update(self)
            version += 1
            defer { waiters = [:] }
            return Array(waiters.values)
        }
        woken.forEach { $0.resume() }
    }

    /// Returns once the version has moved past `seen`, or at `deadline`, whichever is first. Each
    /// continuation is resumed exactly once: by whoever removes it from `waiters`. The deadline's timer is
    /// cancelled as soon as the wait ends, so a woken waiter leaves no sleeping task behind.
    private func nextChange(after seen: Int, deadline: Date) async {
        let id = UUID()
        let delay = max(0, deadline.timeIntervalSinceNow)
        let timer = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled, let self else {
                return
            }
            let expired: CheckedContinuation<Void, Never>? = lock.withLock {
                guard let waiter = waiters.removeValue(forKey: id) else {
                    // Fired before the waiter was registered: tell the registration not to wait.
                    timedOut.insert(id)
                    return nil
                }
                return waiter
            }
            expired?.resume()
        }
        defer {
            timer.cancel()
            lock.withLock { _ = timedOut.remove(id) }
        }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            let resumeNow: Bool = lock.withLock {
                guard version == seen, !timedOut.contains(id) else {
                    return true
                }
                waiters[id] = continuation
                return false
            }
            if resumeNow {
                continuation.resume()
            }
        }
    }
}

extension AuthSessionState {

    /// For failure messages: never a sub, a fresh user's generated username, or a step's payload (a TOTP
    /// setup secret, a delivery destination). A shared sandbox user's fixed name is kept.
    var redactedDescription: String {
        switch self {
        case .signedIn(let user): return "signedIn(\(user.redactedUsername))"
        case .federated: return "federated"
        case .signedOut: return "signedOut"
        case .guest: return "guest"
        case .awaitingChallenge(let step): return "awaitingChallenge(\(step.caseName))"
        case .unavailable(let reason): return "unavailable(\(reason))"
        case .failed(let error): return "failed(\(error.kindName))"
        }
    }
}

extension AuthClientError {

    /// The case's name alone, for failure messages: never its payload (`unexpectedIdentity` carries a username and
    /// a sub, `browserBusy` a session ID) nor its text.
    var kindName: String {
        let described = String(describing: kind)
        return described.firstIndex(of: "(").map { String(described[..<$0]) } ?? described
    }
}

extension AuthClientUser {

    /// The username, unless it is a fresh user's generated `ccit-…` name.
    var redactedUsername: String {
        username.hasPrefix(SandboxSignUp.prefix) ? "a fresh user" : username
    }
}

extension AuthClientSignInStep {

    /// The case's name alone, without its payload.
    var caseName: String {
        let described = String(describing: self)
        return described.firstIndex(of: "(").map { String(described[..<$0]) } ?? described
    }
}

/// Asserts a sign-in step, printing only case names on failure.
func XCTAssertStep(
    _ step: AuthClientSignInStep,
    _ expected: AuthClientSignInStep,
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertTrue(step == expected, "the step is \(step.caseName), expected \(expected.caseName)", file: file, line: line)
}

/// Asserts a session's state, printing neither side's sub on failure.
func XCTAssertState(
    _ state: AuthSessionState,
    _ expected: AuthSessionState,
    _ message: String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertTrue(
        state == expected,
        "the state is \(state.redactedDescription), expected \(expected.redactedDescription). \(message)",
        file: file,
        line: line
    )
}

extension AuthClientSignOutResult {

    /// For failure messages: the case and each error's case name, never an error's payload or text.
    var redactedDescription: String {
        func kind(_ error: AuthClientError?) -> String {
            error?.kindName ?? "nil"
        }
        switch self {
        case .complete:
            return "complete"
        case .partial(let revoke, let global, let hostedUI, let storage):
            return "partial(revokeTokenError: \(kind(revoke)), globalSignOutError: \(kind(global)), "
                + "hostedUIError: \(kind(hostedUI)), storageError: \(kind(storage)))"
        case .failed(let error):
            return "failed(\(error.kindName))"
        }
    }
}

/// Asserts that a sign-out completed: `.complete`, so the session is signed out on this device and nothing
/// failed. A sign-out never throws: `.partial` and `.failed` are results, and either fails this.
func XCTAssertSignOutComplete(
    _ result: AuthClientSignOutResult,
    _ message: String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertTrue(
        result == .complete,
        "the sign-out returned \(result.redactedDescription), expected complete. \(message)",
        file: file,
        line: line
    )
    XCTAssertTrue(
        result.signedOutLocally,
        "the sign-out left the session signed in: \(result.redactedDescription). \(message)",
        file: file,
        line: line
    )
}

/// The error an operation must throw, for assertions on its case.
enum Expect {

    /// The `AuthClientError` `operation` throws; fails the test (and returns `nil`) if it returns, or
    /// throws anything else.
    static func authClientError(
        _ what: String,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ operation: () async throws -> some Any
    ) async -> AuthClientError? {
        do {
            _ = try await operation()
            XCTFail("\(what) should have thrown", file: file, line: line)
        } catch let error as AuthClientError {
            return error
        } catch {
            XCTFail("\(what) should throw an AuthClientError, got \(error)", file: file, line: line)
        }
        return nil
    }

    /// The `CredentialsError` `operation` throws; fails the test (and returns `nil`) otherwise.
    static func credentialsError(
        _ what: String,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ operation: () async throws -> some Any
    ) async -> CredentialsError? {
        do {
            _ = try await operation()
            XCTFail("\(what) should have thrown", file: file, line: line)
        } catch let error as CredentialsError {
            return error
        } catch {
            XCTFail("\(what) should throw a CredentialsError, got \(error)", file: file, line: line)
        }
        return nil
    }
}

extension CredentialsError {

    /// The case, without its strings, for assertions.
    var caseName: String {
        switch self {
        case .notSignedIn: return "notSignedIn"
        case .sessionExpired: return "sessionExpired"
        case .storageUnavailable(let reason, _, _, _): return "storageUnavailable(\(reason))"
        case .notConfigured: return "notConfigured"
        case .unknown: return "unknown"
        }
    }
}

extension AuthClientSignInStep {

    /// Whether this is the TOTP-code step, whatever its payload.
    var isTOTPCode: Bool {
        if case .confirmSignInWithTOTPCode = self {
            return true
        }
        return false
    }

    /// Whether this is the new-password step, whatever its payload.
    var isNewPassword: Bool {
        if case .confirmSignInWithNewPassword = self {
            return true
        }
        return false
    }
}

extension AuthSessionState {

    /// The step, if this session waits on a challenge.
    var pendingStep: AuthClientSignInStep? {
        if case .awaitingChallenge(let step) = self {
            return step
        }
        return nil
    }
}

/// The main configuration's identity pool's two roles, by name, learned independently of the client under
/// test: the raw SDK takes guest credentials (`GetId`, `GetCredentialsForIdentity` with no logins) and a
/// fresh user's credentials (the same with its id token from a raw sign-in), and STS names the role each
/// assumes. No AWS credentials are needed, and no role is named in the configuration. Learned once per
/// process. Only names are compared, and a failing comparison prints neither side, so no account
/// identifier reaches a log.
struct SandboxRoles: Sendable {
    let authenticatedRoleName: String
    let unauthenticatedRoleName: String

    init() async throws {
        self = try await RoleCache.shared.roles()
    }

    fileprivate init(authenticatedRoleName: String, unauthenticatedRoleName: String) {
        self.authenticatedRoleName = authenticatedRoleName
        self.unauthenticatedRoleName = unauthenticatedRoleName
    }

    /// Which of the two roles `provider`'s credentials assume, through STS `GetCallerIdentity`.
    func role(of provider: any AWSCredentialsProvider, region: String) async throws -> Role {
        let identity = try await CallerIdentity.of(provider, region: region)
        let name = try XCTUnwrap(identity.arn.flatMap(CallerIdentity.roleName(of:)), "not an assumed-role ARN")
        switch name {
        case authenticatedRoleName: return .authenticated
        case unauthenticatedRoleName: return .unauthenticated
        default: return .other
        }
    }

    enum Role: Equatable {
        case authenticated, unauthenticated, other
    }
}

/// Learns `SandboxRoles` once per process (`SandboxRoles.init()`).
private actor RoleCache {

    static let shared = RoleCache()

    private var cached: SandboxRoles?

    func roles() async throws -> SandboxRoles {
        if let cached {
            return cached
        }
        let learned = try await Self.learn()
        cached = learned
        return learned
    }

    private static func learn() async throws -> SandboxRoles {
        let configuration = try IntegrationTestEnvironment.configuration()
        guard let identityPool = configuration.identityPool, let userPool = configuration.userPool else {
            throw HarnessError.malformedFixture("\(IntegrationTestEnvironment.outputsResource).json has no identity pool or no user pool.")
        }
        let identity = try await CognitoIdentityClient(
            config: CognitoIdentityClient.CognitoIdentityClientConfig(region: identityPool.region)
        )
        let guestId = try await identity.getId(input: GetIdInput(identityPoolId: identityPool.poolId)).identityId
        let guest = try await identity.getCredentialsForIdentity(input: GetCredentialsForIdentityInput(identityId: guestId))
        let unauthenticated = try await roleName(guest.credentials, region: identityPool.region)

        let user = try await SandboxSignUp.signUp(on: .standard)
        let authenticated: String
        do {
            let tokens = try await SandboxPools.pool(.standard).signIn(user)
            let idToken = try XCTUnwrap(tokens.idToken, "the raw sign-in returned no id token")
            let logins = ["cognito-idp.\(userPool.region).amazonaws.com/\(userPool.poolId)": idToken]
            let userId = try await identity.getId(input: GetIdInput(identityPoolId: identityPool.poolId, logins: logins)).identityId
            let signedIn = try await identity.getCredentialsForIdentity(input: GetCredentialsForIdentityInput(
                identityId: userId,
                logins: logins
            ))
            authenticated = try await roleName(signedIn.credentials, region: identityPool.region)
        } catch {
            _ = try? await SandboxUserCleanup.delete(user)
            throw error
        }
        try await SandboxUserCleanup.delete(user)
        guard authenticated != unauthenticated else {
            throw HarnessError.malformedFixture("The identity pool's guests and users assume the same role.")
        }
        return SandboxRoles(authenticatedRoleName: authenticated, unauthenticatedRoleName: unauthenticated)
    }

    /// The role `credentials` assume, through STS `GetCallerIdentity`.
    private static func roleName(_ credentials: CognitoIdentityClientTypes.Credentials?, region: String) async throws -> String {
        guard let accessKeyId = credentials?.accessKeyId, let secretKey = credentials?.secretKey,
              let sessionToken = credentials?.sessionToken, let expiration = credentials?.expiration else {
            throw HarnessError.malformedFixture("GetCredentialsForIdentity returned incomplete credentials.")
        }
        let provider = FixedCredentialsProvider(credentials: FixedCredentials(
            accessKeyId: accessKeyId,
            secretAccessKey: secretKey,
            sessionToken: sessionToken,
            expiration: expiration
        ))
        let arn = try await CallerIdentity.of(provider, region: region).arn
        return try XCTUnwrap(arn.flatMap(CallerIdentity.roleName(of:)), "not an assumed-role ARN")
    }

    private struct FixedCredentials: AWSTemporaryCredentials {
        let accessKeyId: String
        let secretAccessKey: String
        let sessionToken: String
        let expiration: Date
    }

    private struct FixedCredentialsProvider: AWSCredentialsProvider {
        let credentials: FixedCredentials

        func resolve() async throws -> AWSCredentials {
            credentials
        }
    }
}

/// A plain user pool SDK client for the main configuration's user pool and app client, independent of the
/// client under test, to check what Cognito thinks of a token the client held.
struct RawUserPool: Sendable {
    let userPool: CognitoIdentityProviderClient
    let appClientId: String

    init() throws {
        let pool = try XCTUnwrap(IntegrationTestEnvironment.configuration().userPool)
        self.userPool = try CognitoIdentityProviderClient(
            config: CognitoIdentityProviderClient.CognitoIdentityProviderClientConfig(region: pool.region)
        )
        self.appClientId = pool.appClientId
    }

    /// What `GetTokensFromRefreshToken` answers for `refreshToken`: a new access token, or the error. On a
    /// pool that tracks devices, Cognito refuses a refresh without the session's device key: pass the
    /// access token's `device_key` (`deviceKey(of:)`).
    func refresh(_ refreshToken: String, deviceKey: String? = nil) async -> Result<String, Error> {
        do {
            let output = try await userPool.getTokensFromRefreshToken(input: GetTokensFromRefreshTokenInput(
                clientId: appClientId,
                deviceKey: deviceKey,
                refreshToken: refreshToken
            ))
            guard let accessToken = output.authenticationResult?.accessToken else {
                return .failure(HarnessError.malformedFixture("GetTokensFromRefreshToken returned no access token."))
            }
            return .success(accessToken)
        } catch {
            return .failure(error)
        }
    }

    /// The device key an access token names (`device_key`), or nil on a pool that tracks no devices.
    static func deviceKey(of accessToken: String) -> String? {
        (try? IntegrationTestEnvironment.jwtClaims(accessToken))?["device_key"] as? String
    }

    /// Revokes `refreshToken`, as a test's cleanup when the client under test did not.
    func revoke(_ refreshToken: String) async throws {
        _ = try await userPool.revokeToken(input: RevokeTokenInput(clientId: appClientId, token: refreshToken))
    }
}

/// U-DEF (`SandboxPool.standard`) with an identity pool: the plugin's default backend's outputs, whose
/// identity pool (guest on) federates its user pool. For tests whose user must be a fresh one
/// (`SandboxSignUp` on `.standard`) and that also need AWS credentials.
enum FederatedStandardPool {

    /// The client configuration: the default backend's outputs, which must name an identity pool.
    static func configuration() throws -> AuthClientConfiguration {
        let configuration = try IntegrationTestEnvironment.configuration(.standard)
        guard configuration.identityPool != nil else {
            throw HarnessError.malformedFixture("""
            \(IntegrationTestEnvironment.outputsResource).json has no identity pool: the default backend \
            needs one that federates its user pool, with guest access.
            """)
        }
        return configuration
    }
}

/// Every generic-password item the app can see, in every service and entitled access group, with its
/// modification date: what a test compares before and after an operation to prove which items it wrote.
enum KeychainSnapshot {

    /// One item: its service, access group and account.
    ///
    /// Accounts embed pool IDs, so the description names only the session a record belongs to, never the
    /// account itself.
    struct Item: Hashable, CustomStringConvertible {
        let service: String
        let accessGroup: String
        let account: String

        var description: String {
            if let parsed = SessionRecordKey.parse(account) {
                return "\(service): session \(parsed.sessionId) (\(parsed.kind))"
            }
            return "\(service): a non-session account"
        }
    }

    /// What an item holds, for comparison: its modification date, and a SHA-256 of its data, so a rewrite
    /// within the same second as the snapshot still shows. The data itself is never kept.
    struct Version: Equatable {
        let modified: Date
        let dataDigest: String
    }

    /// Each item's modification date and data digest.
    static func versions() throws -> [Item: Version] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecUseDataProtectionKeychain as String: true,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return [:]
        }
        guard status == errSecSuccess, let rows = result as? [[String: Any]] else {
            throw HarnessError.keychain("SecItemCopyMatching listing every generic password", status)
        }
        var versions: [Item: Version] = [:]
        for row in rows {
            let item = Item(
                service: row[kSecAttrService as String] as? String ?? "",
                accessGroup: row[kSecAttrAccessGroup as String] as? String ?? "",
                account: row[kSecAttrAccount as String] as? String ?? ""
            )
            let data = row[kSecValueData as String] as? Data ?? Data()
            versions[item] = Version(
                modified: row[kSecAttrModificationDate as String] as? Date ?? .distantPast,
                dataDigest: SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
            )
        }
        return versions
    }
}

/// The new-password user this run used up, if any.
///
/// Only an administrator call (`AdminCreateUser`, `AdminSetUserPassword`) puts a user in
/// `FORCE_CHANGE_PASSWORD`, which the test bundle cannot make, so CH-1 cannot use a fresh user the way the
/// delete-user and global sign-out tests do. It takes the first user of the default credentials file's
/// `new_password_required_usernames` still in that state, as the plugin's `testNewPasswordRequired` does,
/// and sets a new password of its own. Each user is used once; another run (the plugin's suite, or this
/// suite, against the same backend) may take one at any time, so every reader moves on to the next.
/// `SandboxProvisioningTests` runs after `ChallengeTests` in the default order: once CH-1 has *attempted* a
/// new password (recorded before the call, so a confirmation that changed the password but then failed
/// still counts), it checks that user in either state.
enum PerRunUsers {

    /// The failure when a new-password user refuses the credentials file's temporary password while Cognito
    /// still holds it in `FORCE_CHANGE_PASSWORD`: the temporary password is wrong, not the user used up.
    static var wrongTemporaryPassword: String {
        """
        A new-password user in \(IntegrationTestEnvironment.credentialsResource(for: IntegrationTestEnvironment.extrasRole)).json \
        refuses new_password_required_temporary_password although it still waits for a new password: the \
        temporary password in the credentials file is wrong.
        """
    }

    /// Whether Cognito still holds `username` in `FORCE_CHANGE_PASSWORD`, asked without changing it:
    /// `ForgotPassword` refuses such a user with `NotAuthorizedException` (its password cannot be reset in
    /// that state), and answers a user who has set a password otherwise (a code sent, or no verified
    /// address to send one to). Asked only about a user whose temporary password was just refused.
    static func stillAwaitsANewPassword(_ username: String, on pool: SandboxPoolClient) async -> Bool {
        do {
            _ = try await pool.client.forgotPassword(input: ForgotPasswordInput(clientId: pool.clientId, username: username))
            return false
        } catch is AWSCognitoIdentityProvider.NotAuthorizedException {
            return true
        } catch {
            return false
        }
    }

    /// Whether `username` now refuses the temporary password, with a raw sign-in that answers no challenge:
    /// the proof that another run took the user.
    static func refusesTemporaryPassword(_ username: String, _ temporary: SandboxSecret, on pool: SandboxPoolClient) async throws -> Bool {
        do {
            _ = try await pool.passwordSignIn(TestUser(username: username, password: temporary.value))
            return false
        } catch is AWSCognitoIdentityProvider.NotAuthorizedException {
            return true
        }
    }

    private static let lock = NSLock()
    private nonisolated(unsafe) static var attempt: TestUser?

    /// The user this run's challenge test tried to set a new password for, with that new password.
    static var newPasswordAttempt: TestUser? {
        get { lock.withLock { attempt } }
        set { lock.withLock { attempt = newValue } }
    }
}
