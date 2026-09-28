//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
@_spi(AmplifyExperimental) import AmplifyFoundation
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
        case .federated: return "federated"
        case .awaitingChallenge(let step): return "awaitingChallenge(\(step.caseName))"
        case .unavailable(let reason): return "unavailable(\(reason))"
        case .failed(let error): return "failed(\(error.kind))"
        }
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

/// The identity pool's two roles, by name, from `state.json`. Only names are compared, and a failing
/// comparison prints neither side, so no account identifier reaches a log.
struct SandboxRoles {
    let authenticatedRoleName: String
    let unauthenticatedRoleName: String

    private struct Fields: Decodable {
        let authRoleArn: String
        let unauthRoleArn: String
    }

    init() throws {
        let fields = try JSONDecoder().decode(
            Fields.self,
            from: IntegrationTestEnvironment.data(forResource: IntegrationTestEnvironment.stateResource)
        )
        guard let authenticated = fields.authRoleArn.split(separator: "/").last,
              let unauthenticated = fields.unauthRoleArn.split(separator: "/").last else {
            throw HarnessError.malformedFixture("state.json's role ARNs have no role name.")
        }
        self.authenticatedRoleName = String(authenticated)
        self.unauthenticatedRoleName = String(unauthenticated)
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

/// A plain user pool SDK client for the sandbox pool, independent of the client under test, to check
/// what Cognito thinks of a token the client held.
struct RawUserPool: Sendable {
    let userPool: CognitoIdentityProviderClient
    let appClientId: String

    init() throws {
        try IntegrationTestEnvironment.requireProvisioned()
        let state = try IntegrationTestEnvironment.state()
        self.userPool = try CognitoIdentityProviderClient(
            config: CognitoIdentityProviderClient.CognitoIdentityProviderClientConfig(region: state.region)
        )
        self.appClientId = state.appClientId
    }

    /// What `GetTokensFromRefreshToken` answers for `refreshToken`: a new access token, or the error.
    func refresh(_ refreshToken: String) async -> Result<String, Error> {
        do {
            let output = try await userPool.getTokensFromRefreshToken(input: GetTokensFromRefreshTokenInput(
                clientId: appClientId,
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

    /// Revokes `refreshToken`, as a test's cleanup when the client under test did not.
    func revoke(_ refreshToken: String) async throws {
        _ = try await userPool.revokeToken(input: RevokeTokenInput(clientId: appClientId, token: refreshToken))
    }
}

/// U-DEF (`SandboxPool.standard`) with an identity pool: the default pool through its `plugin` app client,
/// federated into the plugin suites' identity pool (P-13, guest on, permissionless roles), which is the
/// only identity pool in the sandbox that accepts U-DEF's tokens. For tests whose user must be a fresh one
/// (`SandboxSignUp` on `.standard`) and that also need AWS credentials. Read-only: P-13 is provisioned by
/// `infra/parity.py` with the plugin suites' resources, and nothing here changes it.
enum FederatedStandardPool {

    private struct Fields: Decodable {
        struct Parity: Decodable {
            struct Pool: Decodable {
                let clients: [String: String]?
            }

            let pools: [String: Pool]
            let pluginIdentityPoolId: String?
        }

        let parity: Parity?
    }

    /// The client configuration: U-DEF's outputs, with the `plugin` app client and P-13's identity pool.
    static func configuration() throws -> AuthClientConfiguration {
        let standard = try XCTUnwrap(IntegrationTestEnvironment.configuration(.standard).userPool)
        let fields = try JSONDecoder().decode(
            Fields.self,
            from: IntegrationTestEnvironment.data(forResource: IntegrationTestEnvironment.stateResource)
        )
        guard let identityPoolId = fields.parity?.pluginIdentityPoolId,
              let pluginClientId = fields.parity?.pools[SandboxPool.standard.stateKey]?.clients?["plugin"] else {
            throw HarnessError.malformedFixture("""
            state.json has no plugin identity pool (P-13) or no default-pool plugin client. Re-run \
            infra/provision.sh with the plugin suites' parity resources, then rebuild.
            """)
        }
        return try AuthClientConfiguration(
            userPool: .init(
                poolId: standard.poolId,
                appClientId: pluginClientId,
                region: standard.region,
                passwordPolicy: standard.passwordPolicy,
                usernameAttributes: standard.usernameAttributes,
                standardRequiredAttributes: standard.standardRequiredAttributes,
                verificationMechanisms: standard.verificationMechanisms,
                mfaEnforcement: standard.mfaEnforcement,
                mfaMethods: standard.mfaMethods
            ),
            identityPool: .init(poolId: identityPoolId, region: standard.region, unauthenticatedIdentitiesEnabled: true)
        )
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

/// Whether this run has already used up `dave`.
///
/// `prepare-run.sh` resets dave (P-3) to `FORCE_CHANGE_PASSWORD` before every run, and CH-1 then answers
/// his new-password challenge. Only an administrator call (`AdminCreateUser`, `AdminSetUserPassword`) puts
/// a user in that state, which the test bundle cannot make, so CH-1 cannot use a fresh user the way the
/// delete-user and global sign-out tests do. `SandboxProvisioningTests` runs after `ChallengeTests` in the
/// default order. Once CH-1 has *attempted* the new password (set before the call, so a confirmation that
/// changed the password but then failed still counts), it accepts dave in either state.
enum PerRunUsers {
    private static let lock = NSLock()
    private nonisolated(unsafe) static var daveAttempted = false

    /// Whether this run's challenge test has tried to set dave's new password.
    static var daveNewPasswordAttempted: Bool {
        get { lock.withLock { daveAttempted } }
        set { lock.withLock { daveAttempted = newValue } }
    }
}
