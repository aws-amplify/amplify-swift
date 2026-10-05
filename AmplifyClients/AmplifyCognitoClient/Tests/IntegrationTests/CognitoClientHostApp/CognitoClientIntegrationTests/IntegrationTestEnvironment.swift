//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Shared with CognitoClientUITests (the hosted-UI UI tests), which compiles this file and the six other
// shared sandbox helpers (IntegrationTestEnvironment, PluginTestConfiguration, SandboxPools, SandboxSignUp,
// SandboxUserCleanup, CodeSink, TOTP) and nothing else from this folder. Keep it self-contained: it may use only those files,
// AmplifyCognitoClient, AWSCognitoIdentityProvider, Foundation, Security, CryptoKit and XCTest.

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import Foundation
import Security
import XCTest

/// The test configuration, as copied into this test bundle at build time, and the helpers the suites share.
///
/// The suites read the AWSCognitoAuthPlugin integration suites' own configuration files, by the plugin's
/// names: the files CI downloads into `~/.aws-amplify/amplify-ios/testconfiguration/`
/// (`.github/composite_actions/download_test_configuration`, `resource_subfolder: auth`), or that
/// `infra/plugin-configs.py --dir <dir>` writes from the sandbox for a local run. The target's "Copy test
/// configuration" build phase copies them from `$COGNITO_CLIENT_INTEG_DIR` (default
/// `~/.aws-amplify/amplify-ios/testconfiguration`) into the built `.xctest` bundle, the same build-time copy
/// `AuthHostApp` makes. A missing file is named in a build warning, and every test that needs it fails
/// with a message naming it. The copy lives only in DerivedData; nothing account-specific is committed.
///
/// Each client role is one of the plugin's files (`SandboxPool.outputsResource`): its Gen2 outputs file, or,
/// where the plugin's CI has only the Gen1 file for that backend (`SandboxPool.gen1Resource`), that file
/// translated into the equivalent Gen2 outputs (`PluginTestConfiguration`). The client itself reads Gen2
/// only. The identity-only role is derived from the default backend's outputs without its user pool
/// (`identityOnlyAuthSection()`). No user or secret is seeded: suites sign their own users up, read codes
/// through each file's `data` API (`CodeSink`), and take the rest from the default backend's credentials file
/// (`credentials()`), which the plugin's CI does not provide.
enum IntegrationTestEnvironment {

    /// The main configuration: the plugin's default backend (`SandboxPool.standard`). The resource name
    /// `AuthClientConfiguration(from:bundle:)` is given, exactly as an app would.
    static let outputsResource = SandboxPool.standard.outputsResource
    /// The default backend's credentials file: its custom-auth answer, its new-password users and the
    /// second identity pool.
    static let credentialsResource = "AWSCognitoAuthPluginIntegrationTests-credentials"

    static var bundle: Bundle {
        Bundle(for: BundleToken.self)
    }

    /// Whether the plugin's default outputs file, or its Gen1 file, was present when the bundle was built.
    static var isProvisioned: Bool {
        hasOutputs(.standard)
    }

    /// Fails (never skips) when the test configuration is missing.
    static func requireProvisioned() throws {
        guard isProvisioned else {
            throw HarnessError.missingFixture(SandboxPool.standard.fixtureName)
        }
    }

    /// Whether a role's outputs file, or the plugin's Gen1 file for its backend, is in the bundle.
    static func hasOutputs(_ pool: SandboxPool) -> Bool {
        if bundle.url(forResource: pool.outputsResource, withExtension: "json") != nil {
            return true
        }
        return pool.gen1Resource.map { bundle.url(forResource: $0, withExtension: "json") != nil } ?? false
    }

    /// The bundle to load a role's Gen2 outputs from, by its `outputsResource` name: the test bundle, or,
    /// when only the plugin's Gen1 file for the backend is there, a directory holding its Gen2 translation.
    static func outputsBundle(_ pool: SandboxPool) throws -> Bundle {
        guard hasOutputs(pool) else {
            throw HarnessError.missingFixture(pool.fixtureName)
        }
        return try PluginTestConfiguration.outputsBundle(pool.outputsResource, in: bundle)
    }

    /// A role's Gen2 outputs document, the one `outputsBundle(_:)` holds.
    static func outputsData(_ pool: SandboxPool) throws -> Data {
        guard hasOutputs(pool) else {
            throw HarnessError.missingFixture(pool.fixtureName)
        }
        return try PluginTestConfiguration.outputsData(pool.outputsResource, in: bundle)
    }

    /// The main client configuration, loaded from the default backend's outputs exactly as an app loads
    /// them.
    static func configuration() throws -> AuthClientConfiguration {
        try configuration(.standard)
    }

    /// The client configuration of one role, loaded from its plugin outputs file (or the Gen2 translation of
    /// the plugin's Gen1 file) exactly as an app loads its outputs file.
    static func configuration(_ pool: SandboxPool) throws -> AuthClientConfiguration {
        try requireProvisioned()
        return try AuthClientConfiguration(from: pool.outputsResource, bundle: outputsBundle(pool))
    }

    /// The raw `auth` section of a role's outputs, for what `AuthClientConfiguration` does not parse, such
    /// as the `oauth` block.
    static func outputsAuthSection(_ pool: SandboxPool) throws -> [String: Any] {
        guard let auth = try outputsDocument(pool)["auth"] as? [String: Any] else {
            throw HarnessError.malformedFixture("\(pool.sourceName) has no auth section.")
        }
        return auth
    }

    /// The identity-only role (P-6′): the default backend's identity pool, guest access and region, and no
    /// user pool. The plugin's file set has no identity-only backend, so it is derived; Gen2 outputs
    /// require a user pool, so it is read raw (and built with the programmatic initializer by the suites
    /// that need a configuration).
    static func identityOnlyAuthSection() throws -> [String: Any] {
        let auth = try outputsAuthSection(.standard)
        guard auth["identity_pool_id"] is String else {
            throw HarnessError.malformedFixture("""
            \(outputsResource).json has no identity pool: the default backend needs one, with guest access.
            """)
        }
        return auth.filter { ["aws_region", "identity_pool_id", "unauthenticated_identities_enabled"].contains($0.key) }
    }

    /// A second identity pool with guest access, other than `identityPoolId` (default: the default
    /// backend's), for the configuration-change rows (CS-3): another backend's identity pool from the
    /// plugin's file set, which federates none of the first one's user pool, or, where none has one (the
    /// sandbox's set), the default credentials file's `second_identity_pool_id`.
    static func secondIdentityPool(besides identityPoolId: String? = nil) throws -> AuthClientConfiguration.IdentityPool {
        let firstPool = try identityPoolId ?? identityOnlyAuthSection()["identity_pool_id"] as? String
        for pool in SandboxPool.allCases {
            guard hasOutputs(pool),
                  let auth = try? outputsAuthSection(pool),
                  let poolId = auth["identity_pool_id"] as? String, poolId != firstPool,
                  auth["unauthenticated_identities_enabled"] as? Bool == true,
                  let region = auth["aws_region"] as? String else {
                continue
            }
            return .init(poolId: poolId, region: region, unauthenticatedIdentitiesEnabled: true)
        }
        let credentials = try credentials()
        guard let poolId = credentials.secondIdentityPoolId, poolId != firstPool,
              let region = poolId.split(separator: ":").first.map(String.init) else {
            throw HarnessError.malformedFixture("""
            No second identity pool: no other outputs file has an identity pool with guest access stated, and \
            \(credentialsResource).json \(credentials.isPresent ? "has no" : "is not in the test bundle, so there is no") \
            second_identity_pool_id.
            """)
        }
        return .init(poolId: poolId, region: region, unauthenticatedIdentitiesEnabled: true)
    }

    /// A role whose user pool does not track devices and whose outputs name an identity pool with guest
    /// access, for the configuration-change rows that refresh a carried session (CS-2, CS-3). Device
    /// records are kept per pool namespace, as the plugin keeps them, so a session carried to a new
    /// namespace leaves its device record behind, and a pool that tracks devices (the default backend)
    /// refuses its refresh without the device key.
    static func untrackedFederatedRole() throws -> SandboxPool {
        for pool in SandboxPool.allCases where !pool.tracksDevices {
            guard hasOutputs(pool),
                  let identityPool = try? configuration(pool).identityPool,
                  identityPool.unauthenticatedIdentitiesEnabled == true else {
                continue
            }
            return pool
        }
        throw HarnessError.malformedFixture("""
        No role without device tracking names an identity pool: this test needs the passwordless or WebAuthn \
        backend's outputs to name an identity pool that federates its user pool, with guest access. A session \
        carried to a new pool namespace leaves its device record behind, and the default backend, which tracks \
        devices, refuses its refresh without the device key.
        """)
    }

    /// The `data` API a role's codes are published to (the plugin's MfaInfo API), from its outputs file.
    ///
    /// A test that reads a code on the default backend names its CI skip (`ciSkip`: `.defaultCodeAPI` or
    /// `.defaultCodeAPIAndVerifiedEmail`), so on CI, where that backend names no code API, it skips with that
    /// reason (`skipOnCIIfMissing(_:present:)`) rather than fail.
    static func codeSinkAPI(_ pool: SandboxPool, ciSkip: CISkipReason? = nil) throws -> CodeSinkAPI {
        let data = try outputsDocument(pool)["data"] as? [String: Any]
        let url = (data?["url"] as? String).flatMap(URL.init(string:))
        let apiKey = (data?["api_key"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        if let ciSkip {
            try skipOnCIIfMissing(ciSkip, present: url != nil && apiKey != nil)
        }
        guard let url, let apiKey else {
            throw HarnessError.malformedFixture("""
            \(pool.sourceName) has no data block with a url and an api_key: this test reads a code \
            Cognito sent a \(pool.rawValue) user, so the backend must publish its codes to the plugin's MfaInfo \
            API (custom email and SMS senders) and name it in its outputs, as the passwordless backend does.
            """)
        }
        return CodeSinkAPI(url: url, apiKey: SandboxSecret(apiKey))
    }

    /// Whether a role's outputs are the sandbox's (`infra/plugin-configs.py --dir`), which marks each Gen2
    /// file it writes with `custom.amplify_cognito_client_integ.sandbox: true`. The plugin's CI files, and
    /// the CI shape `--ci-shape` writes, carry no such block, and a Gen1 file's translation has none.
    ///
    /// A sandbox check (a check of what only this sandbox provisions, which no plugin backend promises and
    /// no plugin test uses, such as a pre-sign-up trigger that refuses users who are not test users) runs
    /// only where this is true, and elsewhere skips, saying so (`requireSandbox(_:_:)`).
    static func isSandbox(_ pool: SandboxPool) -> Bool {
        guard hasOutputs(pool), let document = try? outputsDocument(pool),
              let custom = document["custom"] as? [String: Any],
              let marker = custom["amplify_cognito_client_integ"] as? [String: Any] else {
            return false
        }
        return marker["sandbox"] as? Bool == true
    }

    /// Skips a sandbox check (`isSandbox(_:)`) on a backend that is not the sandbox's, naming the file and
    /// what the check needs: it checks the sandbox's provisioning, which the plugin's backends do not have.
    /// A set that looks like the sandbox's full set (it has the default credentials file, which the plugin's
    /// CI and the CI shape do not) but carries no mark was written before the mark existed: the message says
    /// to write it again.
    static func requireSandbox(_ pool: SandboxPool, _ needs: String) throws {
        guard isSandbox(pool) else {
            let unmarkedFullSet = (try? credentials())?.isPresent == true
            let rewrite = unmarkedFullSet
                ? " This set has the default credentials file, as the sandbox's full set does: if it is one written "
                + "before the mark existed, run infra/plugin-configs.py --dir again and rebuild."
                : ""
            throw XCTSkip("""
            A sandbox check: \(pool.sourceName) is not the sandbox's (no custom.amplify_cognito_client_integ \
            block), and this check needs \(needs), which only the sandbox provisions.\(rewrite)
            """)
        }
    }

    // MARK: - CI skips

    /// What the client's CI job sets to `1` in the test process, through `xcodebuild`'s
    /// `TEST_RUNNER_COGNITO_CLIENT_INTEG_CI_SKIPS` (`run_integration_tests.yml`'s `cognito_client_integ_ci_skips`
    /// input). CI sets it, and the README's recommended local recipe on CI's file set sets it too; a run without
    /// it stays strict.
    static let ciSkipsVariable = "COGNITO_CLIENT_INTEG_CI_SKIPS"

    /// Whether this process runs in the client's CI job (`ciSkipsVariable` is `1`).
    static var isCIRun: Bool {
        ProcessInfo.processInfo.environment[ciSkipsVariable] == "1"
    }

    /// Whether the file set is the sandbox's: any role's outputs carry the sandbox mark (`isSandbox(_:)`), as
    /// every Gen2 file `infra/plugin-configs.py --dir` writes does. The plugin's CI files, and the CI shape,
    /// carry none.
    static var isSandboxFileSet: Bool {
        SandboxPool.allCases.contains { isSandbox($0) }
    }

    /// Skips the test, with `reason`'s message, when it runs on CI (`isCIRun`), the file set is not the
    /// sandbox's (`isSandboxFileSet`) and the resource the reason names is missing (`present` is false).
    /// Otherwise it returns, and the test goes on to fail naming the resource, as it does off CI: a sandbox run
    /// never skips, even with the variable set by mistake, and once CI gains the resource the test runs there.
    static func skipOnCIIfMissing(_ reason: CISkipReason, present: Bool) throws {
        try skipOnCIIfMissing(reason, present: present, isCIRun: isCIRun, isSandboxFileSet: isSandboxFileSet)
    }

    /// Whether `skipOnCIIfMissing(_:present:)` skips, whatever the reason, for a check that must leave one part
    /// out rather than skip the whole test (the every-pool sign-up check's device-alias pool).
    static func skipsOnCI(present: Bool) -> Bool {
        skipsOnCI(present: present, isCIRun: isCIRun, isSandboxFileSet: isSandboxFileSet)
    }

    /// `skipOnCIIfMissing(_:present:)` over the three conditions given, for the offline check
    /// (`HarnessHelperTests`).
    static func skipOnCIIfMissing(
        _ reason: CISkipReason,
        present: Bool,
        isCIRun: Bool,
        isSandboxFileSet: @autoclosure () -> Bool
    ) throws {
        if skipsOnCI(present: present, isCIRun: isCIRun, isSandboxFileSet: isSandboxFileSet()) {
            throw XCTSkip(reason.message)
        }
    }

    /// The rule: skip only when all three hold. The file set is read last, and only by a CI run missing the
    /// resource.
    static func skipsOnCI(present: Bool, isCIRun: Bool, isSandboxFileSet: @autoclosure () -> Bool) -> Bool {
        isCIRun && !present && !isSandboxFileSet()
    }

    /// The default backend's credentials file. Absent keys are nil or empty, and an absent file has none, as
    /// the plugin's `AWSAuthBaseTest` reads it (the plugin's CI provides no credentials file); a test that
    /// needs a key fails naming the file and the key (`PluginCredentials.requireCustomChallengeAnswer()`,
    /// `requireNewPasswordUsers()`).
    static func credentials() throws -> PluginCredentials {
        guard bundle.url(forResource: credentialsResource, withExtension: "json") != nil else {
            return PluginCredentials(fields: [:], isPresent: false)
        }
        let object = try JSONSerialization.jsonObject(with: data(forResource: credentialsResource))
        guard let fields = object as? [String: String] else {
            throw HarnessError.malformedFixture("\(credentialsResource).json is not an object of strings.")
        }
        return PluginCredentials(fields: fields, isPresent: true)
    }

    private static func outputsDocument(_ pool: SandboxPool) throws -> [String: Any] {
        guard let document = try JSONSerialization.jsonObject(with: outputsData(pool)) as? [String: Any] else {
            throw HarnessError.malformedFixture("\(pool.sourceName) is not a JSON object.")
        }
        return document
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

/// A role's code API: the outputs' `data` block (`url`, `api_key`).
struct CodeSinkAPI: Sendable {
    let url: URL
    /// Sent as `x-api-key`. Never printed.
    let apiKey: SandboxSecret
}

/// The client's roles, each read from the plugin integration suites' outputs file for it.
enum SandboxPool: String, CaseIterable, Sendable {
    /// U-DEF, the plugin's default backend: self sign-up with auto-confirm, custom auth, MFA optional,
    /// device tracking, and an identity pool with guest access. Also the main configuration.
    case standard = "default"
    /// The plugin's hosted-UI backend. Its outputs file has the `oauth` block.
    case hostedUI = "hosted-ui"
    /// U-PL: choice-based sign-in (USER_AUTH).
    case passwordless
    /// U-REQ-TS: MFA required, TOTP and SMS.
    case mfaRequiredTOTPSMS = "mfa-req-totp-sms"
    /// U-REQ-E: MFA required with email and SMS.
    case mfaRequiredEmail = "mfa-req-email"
    /// U-REQ-ALL: MFA required, TOTP, SMS and email.
    case mfaRequiredAll = "mfa-req-all"
    /// U-ALIAS: email as the username, device tracking, 5-minute tokens.
    case emailAlias = "email-alias"
    /// U-WA: the plugin's WebAuthn backend, `WEB_AUTHN` with the plugin's relying party (P-10).
    case webAuthn = "webauthn"

    /// Whether the harness reads this role's codes from its plugin file's `data` block: the plugin backends
    /// that capture every email and SMS code (passwordless and the two email-MFA ones). Tests that read a
    /// code run on one of these, unless no such backend has the setting they assert on (README, "Which
    /// backend a code-reading test runs on"); those require the `data` block of their own role's file.
    var capturesCodes: Bool {
        [.passwordless, .mfaRequiredEmail, .mfaRequiredAll].contains(self)
    }

    /// The plugin's Gen1 file for the role's backend, without `.json`, where the plugin has one. It is read,
    /// and translated to Gen2, only when `outputsResource` is absent, as on the plugin's CI, which provides
    /// these backends as Gen1 files only.
    var gen1Resource: String? {
        switch self {
        case .standard, .hostedUI, .mfaRequiredTOTPSMS: PluginTestConfiguration.gen1Resource(for: outputsResource)
        case .passwordless, .mfaRequiredEmail, .mfaRequiredAll, .emailAlias, .webAuthn: nil
        }
    }

    /// The file the role's outputs are read from, for a message about their contents: the Gen2 file, or the
    /// plugin's Gen1 file, marked as translated.
    var sourceName: String {
        if case .gen1(let gen1) = PluginTestConfiguration.source(outputsResource, in: IntegrationTestEnvironment.bundle) {
            return "\(gen1).json (translated to Gen2)"
        }
        return "\(outputsResource).json"
    }

    /// The file a missing-fixture message names: the Gen2 file, and the Gen1 one where the plugin has it.
    var fixtureName: String {
        guard let gen1Resource else {
            return "\(outputsResource).json"
        }
        return "\(outputsResource).json (or its Gen1 \(gen1Resource).json)"
    }

    /// The bundle resource name, without `.json`: the plugin's Gen2 file for the role.
    var outputsResource: String {
        switch self {
        case .standard: "AWSCognitoAuthPluginIntegrationTests-amplify_outputs"
        case .hostedUI: "AWSCognitoAuthPluginHostedUIIntegrationTests-amplify_outputs"
        case .passwordless: "AWSCognitoPluginPasswordlessIntegrationTests-amplify_outputs"
        case .mfaRequiredTOTPSMS: "AWSCognitoAuthPluginMFARequiredIntegrationTests-amplify_outputs"
        case .mfaRequiredEmail: "AWSCognitoEmailMFARequiredTests-amplify_outputs"
        case .mfaRequiredAll: "AWSCognitoAuthEmailMFAWithAllMFATypesRequired-amplify_outputs"
        case .emailAlias: "AWSCognitoAuthPluginDeviceAliasTests-amplify_outputs"
        case .webAuthn: "AWSCognitoPluginWebAuthnIntegrationTests-amplify_outputs"
        }
    }
}

/// The default backend's credentials file (`AWSCognitoAuthPluginIntegrationTests-credentials.json`), with the
/// keys the plugin's suites read and the client suites share: the fixtures only an administrator can make.
struct PluginCredentials: Sendable {
    /// `custom_challenge_answer`: the answer the backend's custom-auth triggers accept, as the plugin's
    /// `AuthCustomSignInTests` read it.
    let customChallengeAnswer: SandboxSecret?
    /// `new_password_required_usernames`, comma-separated: users in `FORCE_CHANGE_PASSWORD`, each usable once,
    /// as the plugin's `AuthSRPSignInTests.testNewPasswordRequired` reads them.
    let newPasswordRequiredUsernames: [String]
    /// `new_password_required_temporary_password`: their temporary password.
    let newPasswordRequiredTemporaryPassword: SandboxSecret?
    /// `second_identity_pool_id`: see `IntegrationTestEnvironment.secondIdentityPool()`.
    let secondIdentityPoolId: String?
    /// Whether the file was in the test bundle at all. The plugin's CI provides none.
    let isPresent: Bool

    init(fields: [String: String], isPresent: Bool) {
        self.isPresent = isPresent
        func value(_ key: String) -> String? {
            fields[key].flatMap { $0.isEmpty ? nil : $0 }
        }
        self.customChallengeAnswer = value("custom_challenge_answer").map(SandboxSecret.init)
        self.newPasswordRequiredUsernames = (value("new_password_required_usernames") ?? "")
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        self.newPasswordRequiredTemporaryPassword = value("new_password_required_temporary_password").map(SandboxSecret.init)
        self.secondIdentityPoolId = value("second_identity_pool_id")
    }

    /// The custom-auth answer; fails without it, except on CI, where it skips (`CISkipReason.customAuthAnswer`).
    func requireCustomChallengeAnswer() throws -> SandboxSecret {
        try IntegrationTestEnvironment.skipOnCIIfMissing(.customAuthAnswer, present: customChallengeAnswer != nil)
        guard let customChallengeAnswer else {
            throw HarnessError.malformedFixture(missing("custom_challenge_answer", "custom-auth triggers that accept it"))
        }
        return customChallengeAnswer
    }

    /// The new-password users and their temporary password; fails without them, except on CI, where it skips
    /// (`CISkipReason.newPasswordUsers`).
    func requireNewPasswordUsers() throws -> (usernames: [String], temporaryPassword: SandboxSecret) {
        try IntegrationTestEnvironment.skipOnCIIfMissing(
            .newPasswordUsers,
            present: !newPasswordRequiredUsernames.isEmpty && newPasswordRequiredTemporaryPassword != nil
        )
        guard !newPasswordRequiredUsernames.isEmpty, let newPasswordRequiredTemporaryPassword else {
            throw HarnessError.malformedFixture(missing(
                "new_password_required_usernames and new_password_required_temporary_password",
                "users an administrator created in FORCE_CHANGE_PASSWORD with that temporary password"
            ))
        }
        return (newPasswordRequiredUsernames, newPasswordRequiredTemporaryPassword)
    }

    /// Where the plugin's suite skips its equivalent test without the key, the client's fails, naming the file
    /// and the key.
    private func missing(_ keys: String, _ backend: String) -> String {
        let file = "\(IntegrationTestEnvironment.credentialsResource).json"
        guard isPresent else {
            return """
            \(file) is not in the test bundle, so there is no \(keys): the default backend needs \(backend), \
            named in that file. The plugin's CI test configuration has no credentials file (its own suite skips \
            these tests without it); a local run gets one from infra/plugin-configs.py --dir.
            """
        }
        return "\(file) has no \(keys): the default backend needs \(backend), as the plugin's own suite does."
    }
}

/// Why a test skips on CI: each case names a resource the plugin's CI does not provide, and its
/// message, the skip's, says so (`IntegrationTestEnvironment.skipOnCIIfMissing(_:present:)`). When CI gains the
/// resource, the test runs there with no change here.
enum CISkipReason: CaseIterable, Sendable {
    /// The custom-auth answer: CA-1…3 and the parity check's custom auth.
    case customAuthAnswer
    /// The new-password users and their temporary password: CH-1 and P-3.
    case newPasswordUsers
    /// The credentials file itself: the fixture check.
    case credentialsFile
    /// A code API on the default backend: AT-2's second half.
    case defaultCodeAPI
    /// A code API on the default backend, and an email its pre-sign-up trigger verifies: RP-3.
    case defaultCodeAPIAndVerifiedEmail
    /// A way to confirm a fresh sign-up on the device-alias backend: DV-10…19, its parity check, and its pool in
    /// the every-pool sign-up check.
    case deviceAliasConfirmation

    /// The skip's message.
    var message: String {
        switch self {
        case .customAuthAnswer:
            "Skipped on CI: the plugin's CI provides no AWSCognitoAuthPluginIntegrationTests-credentials.json "
                + "with custom_challenge_answer, so there is no custom-auth answer. The plugin's AuthCustomSignInTests "
                + "skip on CI for the same reason."
        case .newPasswordUsers:
            "Skipped on CI: the plugin's CI provides no AWSCognitoAuthPluginIntegrationTests-credentials.json "
                + "with new_password_required_usernames and new_password_required_temporary_password. The plugin's "
                + "testNewPasswordRequired skips on CI for the same reason."
        case .credentialsFile:
            "Skipped on CI: the plugin's CI downloads no AWSCognitoAuthPluginIntegrationTests-credentials.json, "
                + "so there is no fixture to check."
        case .defaultCodeAPI:
            "Skipped on CI: the plugin's default backend (AWSCognitoAuthPluginIntegrationTests-amplifyconfiguration.json) "
                + "names no code API, so the code this test reads cannot be captured."
        case .defaultCodeAPIAndVerifiedEmail:
            "Skipped on CI: the plugin's default backend (AWSCognitoAuthPluginIntegrationTests-amplifyconfiguration.json) "
                + "names no code API, and its pre-sign-up trigger does not verify the email a password reset is sent to."
        case .deviceAliasConfirmation:
            "Skipped on CI: the plugin's device-alias backend (AWSCognitoAuthPluginDeviceAliasTests-amplify_outputs.json) "
                + "has no pre-sign-up trigger that confirms a fresh sign-up and names no code API, so no user is signed "
                + "up there."
        }
    }
}

/// A user and its password. The password is deliberately excluded from every textual representation,
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
            \(name) is not in the test bundle. The build phase copies the plugin's test configuration from \
            $COGNITO_CLIENT_INTEG_DIR (default ~/.aws-amplify/amplify-ios/testconfiguration, where CI \
            downloads it). For a local run, write it with infra/plugin-configs.py --dir <dir>, then rebuild \
            with COGNITO_CLIENT_INTEG_DIR=<dir>.
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
