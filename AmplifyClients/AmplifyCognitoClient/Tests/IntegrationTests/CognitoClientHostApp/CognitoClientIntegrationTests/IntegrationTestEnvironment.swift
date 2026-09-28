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

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import Foundation
import Security

/// The sandbox fixtures, as copied into this test bundle at build time, and the helpers the suites share.
///
/// Nothing account-specific is committed. The target's "Copy sandbox configuration" build phase
/// copies `amplify_outputs.json`, `state.json` and `users.json` from
/// `$COGNITO_CLIENT_INTEG_DIR` (default `~/.amplify-cognito-client-integ`, which
/// `infra/provision.sh` writes) into the built `.xctest` bundle — the same build-time copy
/// `AuthHostApp` uses for `~/.aws-amplify/amplify-ios/testconfiguration/`. The copy lives only in
/// DerivedData.
enum IntegrationTestEnvironment {

    /// The resource name `AuthClientConfiguration(from:bundle:)` is given, exactly as an app would.
    static let outputsResource = "amplify_outputs"
    static let stateResource = "cognito-client-integ-state"
    static let usersResource = "cognito-client-integ-users"

    static var bundle: Bundle {
        Bundle(for: BundleToken.self)
    }

    /// Whether `provision.sh` output was present when the bundle was built.
    static var isProvisioned: Bool {
        bundle.url(forResource: outputsResource, withExtension: "json") != nil
    }

    /// Fails (never skips) when the sandbox fixtures are missing.
    static func requireProvisioned() throws {
        guard isProvisioned else {
            throw HarnessError.missingFixture("\(outputsResource).json")
        }
    }

    /// The resource ids `provision.sh` recorded — an independent source to check the parsed
    /// configuration against.
    static func state() throws -> SandboxState {
        try JSONDecoder().decode(SandboxState.self, from: data(forResource: stateResource))
    }

    /// The client configuration loaded from the provisioned outputs, exactly as an app loads it.
    static func configuration() throws -> AuthClientConfiguration {
        try requireProvisioned()
        return try AuthClientConfiguration(from: outputsResource, bundle: bundle)
    }

    /// The client configuration of one plugin-parity pool (P-6), loaded from
    /// `<pool>-amplify_outputs.json` exactly as an app loads its outputs file.
    static func configuration(_ pool: SandboxPool) throws -> AuthClientConfiguration {
        try requireProvisioned()
        guard bundle.url(forResource: pool.outputsResource, withExtension: "json") != nil else {
            throw HarnessError.missingFixture("\(pool.outputsResource).json")
        }
        return try AuthClientConfiguration(from: pool.outputsResource, bundle: bundle)
    }

    /// The raw `auth` section of an outputs file, for what `AuthClientConfiguration` does not parse:
    /// the `oauth` block, and the identity-only file, which has no user pool.
    static func outputsAuthSection(_ resource: String) throws -> [String: Any] {
        let object = try JSONSerialization.jsonObject(with: data(forResource: resource))
        guard let auth = (object as? [String: Any])?["auth"] as? [String: Any] else {
            throw HarnessError.malformedFixture("\(resource).json has no auth section.")
        }
        return auth
    }

    /// The provisioned users and carol's TOTP secret.
    static func users() throws -> SandboxUsers {
        let object = try JSONSerialization.jsonObject(with: data(forResource: usersResource))
        guard let fields = object as? [String: String] else {
            throw HarnessError.malformedFixture("\(usersResource).json is not an object of strings.")
        }
        return try SandboxUsers(fields: fields)
    }

    // MARK: - Session IDs

    /// A session ID no other test, and no earlier run, uses: `<tag>-<8 hex digits>`.
    static func uniqueSessionID(_ tag: String) throws -> SessionID {
        let suffix = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(8).lowercased()
        return try SessionID.named("\(tag)-\(suffix)")
    }

    // MARK: - Keychain

    /// The access group an item lands in when written with none: the first entry of the app's
    /// `keychain-access-groups` entitlement, team prefix included.
    static func defaultAccessGroup() throws -> String {
        let service = "com.amplify.cognitoClient.integration.groupDiscovery.\(UUID().uuidString)"
        let account = "default-group-discovery"
        let base: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecUseDataProtectionKeychain as String: true
        ]
        var add = base
        add[kSecAttrAccount as String] = account
        add[kSecValueData as String] = Data()
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let addStatus = SecItemAdd(add as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw HarnessError.keychain("SecItemAdd for group discovery", addStatus)
        }
        defer { SecItemDelete(base as CFDictionary) }

        var query = base
        query[kSecAttrAccount as String] = account
        query[kSecReturnAttributes as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let group = (result as? [String: Any])?[kSecAttrAccessGroup as String] as? String else {
            throw HarnessError.keychain("SecItemCopyMatching for group discovery", status)
        }
        return group
    }

    /// The second group in `CognitoClientHostApp.entitlements`: the default group plus `Shared`.
    static func sharedAccessGroup() throws -> String {
        try defaultAccessGroup(plus: "Shared")
    }

    /// The third group in `CognitoClientHostApp.entitlements` (P-11): the default group plus `Shared2`.
    static func secondSharedAccessGroup() throws -> String {
        try defaultAccessGroup(plus: "Shared2")
    }

    private static func defaultAccessGroup(plus suffix: String) throws -> String {
        let defaultGroup = try defaultAccessGroup()
        guard defaultGroup.hasSuffix("com.aws.amplify.cognitoclient.CognitoClientHostApp") else {
            throw HarnessError.malformedFixture("Unexpected default access group \(defaultGroup).")
        }
        return defaultGroup + suffix
    }

    /// The keychain service the client and the plugin both store session records under.
    static let sessionService = SessionRecordStore.unsharedService

    /// Every account in `service`, sorted, read straight from the keychain with an attributes-only
    /// listing. Scoped to `accessGroup` when one is given; otherwise every entitled group is listed.
    static func rawKeychainAccounts(service: String = sessionService, accessGroup: String? = nil) throws -> [String] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecUseDataProtectionKeychain as String: true,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return []
        }
        guard status == errSecSuccess, let rows = result as? [[String: Any]] else {
            throw HarnessError.keychain("SecItemCopyMatching listing \(service)", status)
        }
        return rows.compactMap { $0[kSecAttrAccount as String] as? String }.sorted()
    }

    // MARK: - Tokens

    /// The claims of a JWT's payload. The signature is not checked: these are tokens the test itself
    /// just received from Cognito.
    static func jwtClaims(_ token: String) throws -> [String: Any] {
        let parts = token.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else {
            throw HarnessError.malformedToken("expected 3 segments, found \(parts.count)")
        }
        var base64 = parts[1].replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)
        guard let payload = Data(base64Encoded: base64),
              let claims = try JSONSerialization.jsonObject(with: payload) as? [String: Any] else {
            throw HarnessError.malformedToken("the payload is not base64url-encoded JSON")
        }
        return claims
    }

    // MARK: - Private

    static func data(forResource resource: String) throws -> Data {
        guard let url = bundle.url(forResource: resource, withExtension: "json") else {
            throw HarnessError.missingFixture("\(resource).json")
        }
        return try Data(contentsOf: url)
    }

    private final class BundleToken {}
}

/// `state.json` as written by `infra/provision.sh`.
struct SandboxState: Decodable, Sendable {
    let region: String
    let userPoolId: String
    let appClientId: String
    let identityPoolId: String
    /// The plugin-parity resources `infra/parity.py` recorded; nil before it ran.
    let parity: ParityState?
}

/// The `parity` section of `state.json`. Only what the tests read.
struct ParityState: Decodable, Sendable {
    struct Pool: Decodable, Sendable {
        /// The template features left off until a manual step is done, e.g. `email-mfa` until the SES
        /// identity is verified, or `sms-mfa` while there is no SMS configuration. Empty when complete.
        let pending: [String]?
    }

    let pools: [String: Pool]
    /// The code sink's AppSync GraphQL endpoint (P-5c). Its API key is `users.json` `codeSinkApiKey`.
    let codeSinkUrl: String

    func pending(_ pool: SandboxPool) -> [String] {
        pools[pool.stateKey]?.pending ?? []
    }
}

/// The plugin-parity backends (P-6), each with its own
/// `<rawValue>-amplify_outputs.json`, the plugin's file naming.
enum SandboxPool: String, CaseIterable, Sendable {
    /// U-DEF, the plugin's default backend: self sign-up with auto-confirm, custom auth, MFA optional,
    /// device tracking.
    case standard = "default"
    /// U-DEF's hosted-UI app client (P-7). Its outputs file has the `oauth` block.
    case hostedUI = "hosted-ui"
    /// U-PL: choice-based sign-in (USER_AUTH).
    case passwordless
    /// U-REQ-TS: MFA required, TOTP (and SMS once configured).
    case mfaRequiredTOTPSMS = "mfa-req-totp-sms"
    /// U-REQ-E: MFA required with email and SMS, once SES and SMS are configured.
    case mfaRequiredEmail = "mfa-req-email"
    /// U-REQ-ALL: MFA required, TOTP (plus SMS and email once configured).
    case mfaRequiredAll = "mfa-req-all"
    /// U-ALIAS: email as the username, device tracking, 5-minute tokens.
    case emailAlias = "email-alias"
    /// U-WA: the plugin's WebAuthn backend, `WEB_AUTHN` with the plugin's relying party (P-10).
    case webAuthn = "webauthn"

    /// The bundle resource name, without `.json`.
    var outputsResource: String {
        "\(rawValue)-amplify_outputs"
    }

    /// The pool's key in `state.json`'s `parity.pools`.
    var stateKey: String {
        self == .hostedUI ? SandboxPool.standard.rawValue : rawValue
    }

    /// The identity-only identity pool's outputs file (P-6′). It has no user pool, which
    /// `AuthClientConfiguration(from:)` does not accept yet; read it with `outputsAuthSection(_:)`.
    static let identityOnlyOutputsResource = "identity-only-amplify_outputs"
}

/// `users.json` as written by `infra/provision.sh`: every user's password, and carol's TOTP secret.
///
/// `prepare-run.sh` keeps the values stable, so a `test-without-building` re-run sees the same ones.
struct SandboxUsers: Sendable {
    /// Confirmed, permanent passwords, no MFA preference.
    let alice: TestUser
    let bob: TestUser
    /// Confirmed, TOTP enrolled and preferred (P-2).
    let carol: TestUser
    let carolTOTPSecret: TOTPSecret
    /// Reset to `FORCE_CHANGE_PASSWORD` with `password` before every run (P-3). The challenge test
    /// sets `newPassword`.
    let dave: TestUser
    let daveNewPassword: TestUser
    /// Recreated before every run (P-4), because the delete-user test deletes her.
    let erin: TestUser
    /// The code sink's AppSync API key (P-5c), sent as `x-api-key`.
    let codeSinkAPIKey: SandboxSecret
    /// The answer the custom-auth triggers accept (P-5b).
    let customChallengeAnswer: SandboxSecret

    /// Every key `users.json` must hold.
    static let requiredKeys = [
        "alice", "bob", "carol", "carolTotpSecret", "codeSinkApiKey", "customChallengeAnswer",
        "daveNew", "daveTemporary", "erin"
    ]

    init(fields: [String: String]) throws {
        func value(_ key: String) throws -> String {
            guard let value = fields[key], !value.isEmpty else {
                throw HarnessError.malformedFixture("""
                users.json has no \(key). Re-run infra/provision.sh (it adds missing users and keeps \
                existing passwords), then rebuild.
                """)
            }
            return value
        }
        self.alice = try TestUser(username: "alice", password: value("alice"))
        self.bob = try TestUser(username: "bob", password: value("bob"))
        self.carol = try TestUser(username: "carol", password: value("carol"))
        self.carolTOTPSecret = try TOTPSecret(value("carolTotpSecret"))
        self.dave = try TestUser(username: "dave", password: value("daveTemporary"))
        self.daveNewPassword = try TestUser(username: "dave", password: value("daveNew"))
        self.erin = try TestUser(username: "erin", password: value("erin"))
        self.codeSinkAPIKey = try SandboxSecret(value("codeSinkApiKey"))
        self.customChallengeAnswer = try SandboxSecret(value("customChallengeAnswer"))
    }
}

/// A provisioned user. The password is deliberately excluded from every textual representation,
/// so an assertion failure or a log line cannot leak it.
struct TestUser: Sendable, CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    let username: String
    let password: String

    var description: String { username }
    var debugDescription: String { "TestUser(\(username))" }
    var customMirror: Mirror { Mirror(self, children: ["username": username]) }
}

/// A base32 TOTP secret, redacted from every textual representation like `TestUser`'s password.
struct TOTPSecret: Sendable, CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    let base32: String

    init(_ base32: String) {
        self.base32 = base32
    }

    var description: String { "TOTPSecret(redacted)" }
    var debugDescription: String { description }
    var customMirror: Mirror { Mirror(self, children: [:]) }
}

/// Any other sandbox secret, redacted from every textual representation like `TOTPSecret`.
struct SandboxSecret: Sendable, CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    let value: String

    init(_ value: String) {
        self.value = value
    }

    var description: String { "SandboxSecret(redacted)" }
    var debugDescription: String { description }
    var customMirror: Mirror { Mirror(self, children: [:]) }
}

enum HarnessError: Error, CustomStringConvertible {
    case missingFixture(String)
    case malformedFixture(String)
    case malformedToken(String)
    case keychain(String, OSStatus)
    case timedOut(String)

    var description: String {
        switch self {
        case .missingFixture(let name):
            return """
            \(name) is not in the test bundle. Run \
            AmplifyClients/AmplifyCognitoClient/Tests/IntegrationTests/infra/provision.sh, then rebuild: \
            the build phase copies it from $COGNITO_CLIENT_INTEG_DIR (default ~/.amplify-cognito-client-integ).
            """
        case .malformedFixture(let message):
            return message
        case .malformedToken(let reason):
            return "Not a JWT: \(reason)."
        case .keychain(let operation, let status):
            return "\(operation) returned \(status)."
        case .timedOut(let what):
            return "Timed out waiting for \(what)."
        }
    }
}
