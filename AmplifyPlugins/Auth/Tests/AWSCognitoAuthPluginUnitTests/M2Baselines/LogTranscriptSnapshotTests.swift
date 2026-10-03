//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentity
import AWSCognitoIdentityProvider
import Foundation
import XCTest
@testable import Amplify
@_spi(KeychainStore) @testable import AWSPluginsCore
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// The log-transcript gate: the plugin logs the same lines, with the same category, namespace and level,
/// modulo normalisation (`LogTranscriptNormaliser`).
///
/// A capturing Amplify logging plugin records every line of seven fixed scenarios. The environment is
/// built with the production logger (`AmplifyEngineLogRouter()`, which resolves to
/// `AWSCognitoAuthPlugin.log`'s scope; before the engine had its own logging it was
/// `AWSCognitoAuthPlugin.log`), not the tests' usual
/// `awsCognitoAuthPluginTest` category, so every shape resolves as it does in an app. Each line is
/// normalised (`LogTranscriptNormaliser`), and the scenario's lines are compared, as a sorted multiset,
/// with `TestResources/GoldenLogs/transcript.json`, recorded before the engine extraction.
///
/// Why a sorted multiset: actions run on their own tasks, so the interleaving of lines from different
/// tasks is not deterministic. Which lines are logged, how often, and at which scope and level is.
///
/// Regenerate only for a reviewed, intended change: `AMPLIFY_GENERATE_GOLDEN=1 swift test --filter LogTranscriptSnapshotTests`.
final class LogTranscriptSnapshotTests: XCTestCase, @unchecked Sendable {

    struct Transcript: Codable, Equatable {
        let note: String
        let scenarios: [String: [CapturingLoggingPlugin.Line]]
    }

    static var fileURL: URL {
        GoldenFiles.directory("GoldenLogs").appendingPathComponent("transcript.json")
    }

    private var capture: CapturingLoggingPlugin!
    private var savedPlugins: [PluginKey: LoggingCategoryPlugin] = [:]

    override func setUp() async throws {
        capture = CapturingLoggingPlugin()
        TranscriptMachines.shared.start(capturingWith: capture)
        savedPlugins = Amplify.Logging.plugins
        Amplify.Logging.plugins = [capture.key: capture]
        Amplify.Logging.logLevel = .verbose
    }

    override func tearDown() async throws {
        // Let the scenarios' machines finish, and their states be logged, before the plugin table is
        // swapped back and Amplify is reset.
        await TranscriptMachines.shared.settle()
        TranscriptMachines.shared.stop()
        Amplify.Logging.plugins = savedPlugins
        await Amplify.reset()
    }

    // MARK: The gate

    /// Test that the normalised log transcript of every scenario is unchanged
    ///
    /// - Given: A capturing logging plugin, and the recorded transcript, as the plugin logs it on this platform
    ///   (`onThisPlatform(_:)`)
    /// - When:
    ///    - Each of the seven scenarios runs against a plugin with mocked services
    /// - Then:
    ///    - Each scenario's normalised lines equal the recorded ones, as a sorted multiset
    ///
    func testTranscriptIsUnchanged() async throws {
        let normaliser = try LogTranscriptNormaliser.fromRepository()
        var scenarios: [String: [CapturingLoggingPlugin.Line]] = [:]
        for scenario in Self.scenarios {
            capture.clear()
            try await scenario.run()
            await TranscriptMachines.shared.settle()
            scenarios[scenario.name] = capture.lines.map(normaliser.normalise).sorted()
        }
        let current = Transcript(
            note: "Recorded at M2 step S0b. Lines are normalised (LogTranscriptNormaliser) and sorted per scenario.",
            scenarios: scenarios
        )
        let currentData = try GoldenFiles.snapshotData(current)
        if let rawDirectory = ProcessInfo.processInfo.environment["AMPLIFY_TRANSCRIPT_RAW_DIR"] {
            try GoldenFiles.write(currentData, to: URL(fileURLWithPath: rawDirectory).appendingPathComponent("transcript.json"))
        }
        if GoldenFiles.isGenerating {
            try GoldenFiles.write(currentData, to: Self.fileURL)
            return
        }
        let recorded = try Self.onThisPlatform(JSONDecoder().decode(Transcript.self, from: Data(contentsOf: Self.fileURL)))
        XCTAssertEqual(Set(current.scenarios.keys), Set(recorded.scenarios.keys))
        for (name, lines) in recorded.scenarios.sorted(by: { $0.key < $1.key }) {
            let now = current.scenarios[name] ?? []
            guard now != lines else { continue }
            let missing = lines.difference(now)
            let extra = now.difference(lines)
            XCTFail("""
            \(name) drifted.
            missing:
            \(missing.map { "  \($0)" }.joined(separator: "\n"))
            extra:
            \(extra.map { "  \($0)" }.joined(separator: "\n"))
            """)
        }
    }

    /// The recorded transcript as the plugin logs it on this platform.
    ///
    /// The transcript was recorded on macOS. `KeychainStoreError.recoverySuggestion`, and the engine's
    /// `EngineCredentialStoreError` copy of it, report a security error other than a missing entitlement from
    /// their `#if os(macOS)` branch, whose `shouldNotHappenReportBugToAWS()` call is at line 78. Every other
    /// platform reports every security error from the `#else` branch, whose call is at line 88. Scenario 6 logs
    /// that text, so off macOS its recorded call site reads line 88. Nothing else changes.
    static func onThisPlatform(_ recorded: Transcript) -> Transcript {
        #if os(macOS)
        return recorded
        #else
        let callSite = "file: AWSPluginsCore/KeychainStoreError.swift\nfunction: recoverySuggestion\nline: "
        return Transcript(
            note: recorded.note,
            scenarios: recorded.scenarios.mapValues { lines in
                lines.map { line in
                    CapturingLoggingPlugin.Line(
                        shape: line.shape,
                        category: line.category,
                        namespace: line.namespace,
                        level: line.level,
                        message: line.message.replacingOccurrences(of: callSite + "78", with: callSite + "88")
                    )
                }.sorted()
            }
        )
        #endif
    }

    /// Test that the public `AuthFlowType` decoder still logs what scenario 7 recorded
    ///
    /// - Given: A capturing logging plugin, and the recorded transcript
    /// - When:
    ///    - A flow with an unknown factor is decoded as the public `AuthFlowType`, the path scenario 7
    ///      took before the stored path moved onto the engine fork
    /// - Then:
    ///    - The normalised lines equal scenario 7's recorded lines
    ///
    func testPublicAuthFlowTypeDecodeLogsAsScenario7() async throws {
        let normaliser = try LogTranscriptNormaliser.fromRepository()
        capture.clear()
        try await Self.unsupportedPublicAuthFactorType()
        await TranscriptMachines.shared.settle()
        let recorded = try JSONDecoder().decode(Transcript.self, from: Data(contentsOf: Self.fileURL))
        let expected = try XCTUnwrap(recorded.scenarios["7-unsupportedAuthFactorType"])
        XCTAssertEqual(capture.lines.map(normaliser.normalise).sorted(), expected)
    }

    /// Test that the normaliser implements its rules
    ///
    /// - Given: Lines as they read after the moves into the engine and the forks
    /// - When:
    ///    - They are normalised
    /// - Then:
    ///    - They read as today's lines do
    ///
    func testNormaliserMapsMovedAndForkedNamesBack() throws {
        let normaliser = try LogTranscriptNormaliser.fromRepository()
        XCTAssertEqual(
            normaliser.normaliseText("InternalAWSCognitoAuth/InitiateAuthSRP.swift Starting execution"),
            normaliser.normaliseText("AWSCognitoAuthPlugin/InitiateAuthSRP.swift Starting execution")
        )
        XCTAssertEqual(
            normaliser.normaliseText("InternalAWSCognitoAuth.EngineAuthFactorType.password"),
            "Amplify.AuthFactorType.password"
        )
        XCTAssertEqual(normaliser.normaliseText("EngineUserPoolTokens(idToken: x)"), "AWSCognitoUserPoolTokens(idToken: x)")
        XCTAssertEqual(normaliser.normaliseText("InternalAWSCognitoAuth.SignInMethod.apiBased"), "AWSCognitoAuthPlugin.SignInMethod.apiBased")
        // The forks must print the legacy names, so their own names are not mapped back.
        XCTAssertEqual(
            normaliser.normaliseText("Error: EngineCredentialStoreError: Unable to find the keychain item"),
            "Error: EngineCredentialStoreError: Unable to find the keychain item"
        )
        XCTAssertEqual(normaliser.normaliseText("EngineAuthError: Something"), "EngineAuthError: Something")
        // Categories and namespaces are never rewritten.
        let forkScoped = CapturingLoggingPlugin.Line(
            shape: "category", category: "EngineAuthFactorType", namespace: "EngineUserPoolTokens", level: "error", message: "m"
        )
        XCTAssertEqual(normaliser.normalise(forkScoped).category, "EngineAuthFactorType")
        XCTAssertEqual(normaliser.normalise(forkScoped).namespace, "EngineUserPoolTokens")
        XCTAssertEqual(
            normaliser.normaliseText("expires 2026-09-24 15:00:00 +0000, id 3F2504E0-4F89-11D3-9A0C-0305E82C3301"),
            "expires <date>, id <uuid>"
        )
        // Printed Swift dictionaries, plain and escaped inside a string, in two hash orders
        XCTAssertEqual(
            normaliser.normaliseText(#"x ["b": 1, "a": "p, q"] y = "[\"d\": [\"f\": 2, \"e\": 3], \"c\": 4]""#),
            normaliser.normaliseText(#"x ["a": "p, q", "b": 1] y = "[\"c\": 4, \"d\": [\"e\": 3, \"f\": 2]]""#)
        )
        // Arrays keep their order
        XCTAssertNotEqual(normaliser.normaliseText(#"["b", "a"]"#), normaliser.normaliseText(#"["a", "b"]"#))
    }
}

// MARK: Scenarios

extension LogTranscriptSnapshotTests {

    struct Scenario {
        let name: String
        let run: () async throws -> Void
    }

    static var scenarios: [Scenario] {
        [
            Scenario(name: "1-srpSignIn", run: srpSignIn),
            Scenario(name: "2-refresh", run: refresh),
            Scenario(name: "3a-fetchSession-signedIn", run: fetchSessionSignedIn),
            Scenario(name: "3b-fetchSession-signedOut", run: fetchSessionSignedOut),
            Scenario(name: "4-globalSignOut-revokeFailure", run: globalSignOutWithRevokeFailure),
            Scenario(name: "5-firstLaunch-noStoredSession", run: firstLaunchWithNoStoredSession),
            Scenario(name: "6-credentialStoreLoadFailure", run: credentialStoreLoadFailure),
            Scenario(name: "7-unsupportedAuthFactorType", run: unsupportedAuthFactorType)
        ]
    }

    /// `{"sub":"transcript-sub","username":"transcript-user","exp":4102444800}` (2100-01-01): never expires.
    static let longLivedAccessToken = "eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0."
        + "eyJzdWIiOiJ0cmFuc2NyaXB0LXN1YiIsInVzZXJuYW1lIjoidHJhbnNjcmlwdC11c2VyIiwiZXhwIjo0MTAyNDQ0ODAwfQ"
        + ".transcript-signature"

    @available(*, deprecated, message: "Builds tokens through the deprecated public initializer, on purpose")
    static var longLivedTokens: EngineUserPoolTokens {
        EngineUserPoolTokens(
            idToken: longLivedAccessToken,
            accessToken: longLivedAccessToken,
            refreshToken: "transcript-refresh-token",
            expiration: Date(timeIntervalSince1970: 4_102_444_800)
        )
    }

    @available(*, deprecated, message: "Builds tokens through the deprecated public initializer, on purpose")
    static var signedInData: SignedInData {
        SignedInData(
            signedInDate: Date(timeIntervalSince1970: 1_700_000_000),
            signInMethod: .apiBased(.userSRP),
            cognitoUserPoolTokens: longLivedTokens
        )
    }

    static var credentials: EngineAWSCredentials {
        EngineAWSCredentials(
            accessKeyId: "TRANSCRIPTACCESSKEY",
            secretAccessKey: "transcript-secret",
            sessionToken: "transcript-session",
            expiration: Date(timeIntervalSince1970: 4_102_444_800)
        )
    }

    static var identityCredentials: CognitoIdentityClientTypes.Credentials {
        CognitoIdentityClientTypes.Credentials(
            accessKeyId: "TRANSCRIPTACCESSKEY",
            expiration: Date(timeIntervalSince1970: 4_102_444_800),
            secretKey: "transcript-secret",
            sessionToken: "transcript-session"
        )
    }

    static var identity: CognitoIdentityBehavior {
        MockIdentity(
            mockGetIdResponse: { _ in .init(identityId: "us-east-1:transcript-identity") },
            mockGetCredentialsResponse: { _ in
                .init(credentials: identityCredentials, identityId: "us-east-1:transcript-identity")
            }
        )
    }

    static var authenticationResult: CognitoIdentityProviderClientTypes.AuthenticationResultType {
        .init(
            accessToken: longLivedAccessToken,
            expiresIn: 3_600,
            idToken: longLivedAccessToken,
            newDeviceMetadata: nil,
            refreshToken: "transcript-refresh-token",
            tokenType: ""
        )
    }

    // 1
    static func srpSignIn() async throws {
        let userPool = MockIdentityProvider(
            mockInitiateAuthResponse: { _ in
                InitiateAuthOutput(
                    authenticationResult: .none,
                    challengeName: .passwordVerifier,
                    challengeParameters: InitiateAuthOutput.validChalengeParams,
                    session: "transcript-session"
                )
            },
            mockRespondToAuthChallengeResponse: { _ in
                RespondToAuthChallengeOutput(
                    authenticationResult: authenticationResult,
                    challengeName: .none,
                    challengeParameters: [:],
                    session: "transcript-session"
                )
            }
        )
        let plugin = await TranscriptPlugin.make(
            initialState: .configured(.signedOut(.init(lastKnownUserName: nil)), .configured, .notStarted),
            userPool: userPool
        )
        let options = AuthSignInRequest.Options(pluginOptions: AWSAuthSignInOptions(authFlowType: .userSRP))
        _ = try await plugin.signIn(username: "transcript-user", password: "transcript-password", options: options)
    }

    // 2
    @available(*, deprecated, message: "Builds tokens through the deprecated public initializer, on purpose")
    static func refresh() async throws {
        let userPool = MockIdentityProvider(
            mockGetTokensFromRefreshTokenResponse: { _ in
                GetTokensFromRefreshTokenOutput(authenticationResult: authenticationResult)
            }
        )
        let plugin = await TranscriptPlugin.make(
            initialState: .configured(
                .signedIn(signedInData),
                .sessionEstablished(.userPoolAndIdentityPool(
                    signedInData: signedInData,
                    identityID: "us-east-1:transcript-identity",
                    credentials: credentials
                )),
                .notStarted
            ),
            userPool: userPool
        )
        _ = try await plugin.fetchAuthSession(options: .forceRefresh())
    }

    // 3a
    @available(*, deprecated, message: "Builds tokens through the deprecated public initializer, on purpose")
    static func fetchSessionSignedIn() async throws {
        let plugin = await TranscriptPlugin.make(
            initialState: .configured(
                .signedIn(signedInData),
                .sessionEstablished(.userPoolAndIdentityPool(
                    signedInData: signedInData,
                    identityID: "us-east-1:transcript-identity",
                    credentials: credentials
                )),
                .notStarted
            ),
            userPool: MockIdentityProvider()
        )
        _ = try await plugin.fetchAuthSession(options: .init())
    }

    // 3b
    static func fetchSessionSignedOut() async throws {
        let plugin = await TranscriptPlugin.make(
            initialState: .configured(.signedOut(.init(lastKnownUserName: nil)), .configured, .notStarted),
            userPool: MockIdentityProvider()
        )
        _ = try await plugin.fetchAuthSession(options: .init())
    }

    // 4
    @available(*, deprecated, message: "Builds tokens through the deprecated public initializer, on purpose")
    static func globalSignOutWithRevokeFailure() async throws {
        let userPool = MockIdentityProvider(
            mockRevokeTokenResponse: { _ in
                throw AWSCognitoIdentityProvider.InternalErrorException(message: "transcript revoke failure")
            },
            mockGlobalSignOutResponse: { _ in .init() }
        )
        let plugin = await TranscriptPlugin.make(
            initialState: .configured(
                .signedIn(signedInData),
                .sessionEstablished(.userPoolAndIdentityPool(
                    signedInData: signedInData,
                    identityID: "us-east-1:transcript-identity",
                    credentials: credentials
                )),
                .notStarted
            ),
            userPool: userPool
        )
        _ = await plugin.signOut(options: .init(globalSignOut: true))
    }

    // 5
    static func firstLaunchWithNoStoredSession() async throws {
        let environment = TranscriptPlugin.environment(
            userPool: MockIdentityProvider(),
            credentialsClient: TranscriptCredentialsClient(loadError: EngineCredentialStoreError.itemNotFound)
        )
        await InitializeAuthConfiguration(authConfiguration: environment.configuration)
            .execute(withDispatcher: MockDispatcher { _ in }, environment: environment)
    }

    // 6
    static func credentialStoreLoadFailure() async throws {
        let environment = TranscriptPlugin.environment(
            userPool: MockIdentityProvider(),
            credentialsClient: TranscriptCredentialsClient(
                loadError: EngineCredentialStoreError.securityError(errSecInteractionNotAllowed)
            )
        )
        await InitializeAuthConfiguration(authConfiguration: environment.configuration)
            .execute(withDispatcher: MockDispatcher { _ in }, environment: environment)
    }

    // 7: the production path to the factor parser: a stored `SignInMethod.apiBased` flow. Now that
    // is `EngineAuthFactorType(rawValue: "X")`, through `EngineAuthFlowType.init(from:)`, a static site on
    // the global engine router, which `AWSCognitoAuthPlugin.init` installs. Before the fork it was
    // `AuthFactorType(rawValue: "X")` through `AuthFlowType.init(from:)`, which
    // `testPublicAuthFlowTypeDecodeLogsAsScenario7` still checks against the same recorded lines.
    static func unsupportedAuthFactorType() async throws {
        EngineLog.install(AmplifyEngineLogRouter())
        let json = Data(#"{"apiBased":{"_0":{"type":"USER_AUTH","preferredFirstFactor":"X"}}}"#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(SignInMethod.self, from: json))
    }

    // 7, through the public type: `AuthFactorType(rawValue: "X")`, through `AuthFlowType.init(from:)`
    // The public `AuthFactorType` logs through the global engine router too, so install the
    // production router here rather than relying on an earlier test having done it.
    static func unsupportedPublicAuthFactorType() async throws {
        EngineLog.install(AmplifyEngineLogRouter())
        let json = Data(#"{"type":"USER_AUTH","preferredFirstFactor":"X"}"#.utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(AuthFlowType.self, from: json))
    }
}

// MARK: Plugin and environment with the production logger

enum TranscriptPlugin {

    static var configuration: AuthConfiguration {
        Defaults.makeDefaultAuthConfigData()
    }

    /// `Defaults.makeDefaultAuthEnvironment`, with the plugin's own logger (shape C) and a credentials
    /// client whose content is fixed.
    static func environment(
        userPool: CognitoUserPoolBehavior,
        identity: @escaping @Sendable () -> CognitoIdentityBehavior = { LogTranscriptSnapshotTests.identity },
        credentialsClient: CredentialStoreStateBehavior = TranscriptCredentialsClient(loadError: EngineCredentialStoreError.itemNotFound)
    ) -> AuthEnvironment {
        let userPoolConfigData = Defaults.makeDefaultUserPoolConfigData()
        let identityPoolConfigData = Defaults.makeIdentityConfigData()
        let userPoolFactory: @Sendable () throws -> CognitoUserPoolBehavior = { userPool }
        let identityFactory: @Sendable () throws -> CognitoIdentityBehavior = { identity() }
        let srpAuthEnvironment = BasicSRPAuthEnvironment(
            userPoolConfiguration: userPoolConfigData,
            cognitoUserPoolFactory: userPoolFactory
        )
        let userPoolEnvironment = BasicUserPoolEnvironment(
            userPoolConfiguration: userPoolConfigData,
            cognitoUserPoolFactory: userPoolFactory,
            cognitoUserPoolASFFactory: Defaults.makeDefaultASF,
            cognitoUserPoolAnalyticsHandlerFactory: Defaults.makeUserPoolAnalytics
        )
        return AuthEnvironment(
            configuration: configuration,
            userPoolConfigData: userPoolConfigData,
            identityPoolConfigData: identityPoolConfigData,
            authenticationEnvironment: BasicAuthenticationEnvironment(
                srpSignInEnvironment: BasicSRPSignInEnvironment(srpAuthEnvironment: srpAuthEnvironment),
                userPoolEnvironment: userPoolEnvironment,
                hostedUIEnvironment: nil
            ),
            authorizationEnvironment: BasicAuthorizationEnvironment(
                identityPoolConfiguration: identityPoolConfigData,
                cognitoIdentityFactory: identityFactory
            ),
            credentialsClient: credentialsClient,
            logger: AmplifyEngineLogRouter()
        )
    }

    /// A plugin whose two state machines are tracked (`TranscriptMachines`), returned once the plugin's
    /// state-change listeners have logged the machines' initial states, so no state goes unlogged.
    static func make(
        initialState: AuthState,
        userPool: CognitoUserPoolBehavior
    ) async -> AWSCognitoAuthPlugin {
        let plugin = AWSCognitoAuthPlugin()
        let environment = environment(userPool: userPool)
        let authActivity = TranscriptMachines.shared.makeActivity()
        let credentialStoreActivity = TranscriptMachines.shared.makeActivity()
        plugin.configure(
            authConfiguration: configuration,
            authEnvironment: environment,
            authStateMachine: AuthStateMachine(
                resolver: TrackingResolver(AuthState.Resolver(logger: AmplifyEngineLogRouter()), activity: authActivity),
                environment: environment,
                initialState: initialState
            ),
            credentialStoreStateMachine: CredentialStoreStateMachine(
                resolver: TrackingResolver(CredentialStoreState.Resolver(), activity: credentialStoreActivity),
                environment: CredentialEnvironment(
                    authConfiguration: configuration,
                    credentialStoreEnvironment: BasicCredentialStoreEnvironment(
                        amplifyCredentialStoreFactory: Defaults.makeAmplifyStore,
                        legacyKeychainStoreFactory: Defaults.makeLegacyStore(service:)
                    ),
                    logger: AmplifyEngineLogRouter()
                ),
                initialState: .idle
            ),
            hubEventHandler: MockAuthHubEventBehavior(),
            analyticsHandler: MockAnalyticsHandler()
        )
        await TranscriptMachines.shared.track(
            TranscriptMachines.Machines(
                auth: authActivity,
                credentialStore: credentialStoreActivity,
                configureOperation: AuthConfigureOperationSettler(plugin)
            )
        )
        return plugin
    }
}

/// The state machines of the plugins the scenarios create, so that a scenario's capture ends
/// deterministically: when every machine is at rest and the plugin's state-change listeners
/// (`AWSCognitoAuthPlugin.listenToStateMachineChanges()`) have logged every state it published.
///
/// Each listener logs one line per published state ("Auth state change:", "Credential Store state
/// change:"), starting with the state current when it subscribed. `track` waits until each has logged the
/// initial state before the scenario runs, so at rest the line counts equal the published-state counts.
/// Nothing here waits on time: the timeout only bounds a machine that never settles, and that fails.
final class TranscriptMachines: @unchecked Sendable {

    static let shared = TranscriptMachines()

    struct Machines {
        let auth: MachineActivity
        let credentialStore: MachineActivity
        let configureOperation: AuthConfigureOperationSettler
    }

    static let authStateLine = "Auth state change:"
    static let credentialStoreStateLine = "Credential Store state change:"

    private let lock = NSLock()
    private var machines: [Machines] = []
    private var capture: CapturingLoggingPlugin?

    func start(capturingWith capture: CapturingLoggingPlugin) {
        lock.withLock {
            self.capture = capture
            machines = []
        }
    }

    func stop() {
        lock.withLock {
            capture = nil
            machines = []
        }
    }

    /// An activity record that re-checks the capture's waiters whenever it changes.
    func makeActivity() -> MachineActivity {
        MachineActivity { [weak self] in
            self?.currentCapture?.recheckWaiters()
        }
    }

    /// Starts tracking a plugin's machines and waits until both listeners have logged the initial state.
    ///
    /// Assumes neither machine changes state before its listener subscribes, so that the listener's first
    /// line is the initial state. That holds for the scenarios: every plugin starts `.configured` (the
    /// configure operation's `configureAuth` event resolves to the same state), and no scenario sends an
    /// event before `make` returns. If it did not hold, a published state would never be logged, the
    /// counts could not become equal, and the wait would fail rather than pass.
    func track(_ plugin: Machines, file: StaticString = #filePath, line: UInt = #line) async {
        lock.withLock { machines.append(plugin) }
        await waitUntilSettled(file: file, line: line)
    }

    /// Waits until every tracked machine is settled, then for the plugins' configure operations, and
    /// stops tracking them.
    func settle(file: StaticString = #filePath, line: UInt = #line) async {
        await waitUntilSettled(file: file, line: line)
        let settled = lock.withLock {
            let settled = machines
            machines = []
            return settled
        }
        for plugin in settled {
            await plugin.configureOperation.wait()
        }
    }

    private var currentCapture: CapturingLoggingPlugin? {
        lock.withLock { capture }
    }

    private var tracked: [Machines] {
        lock.withLock { machines }
    }

    private func waitUntilSettled(file: StaticString, line: UInt) async {
        guard let capture = currentCapture else {
            return
        }
        let settled = await capture.waitUntil(timeout: 30) { [weak self] in
            self?.isSettled(capture) ?? true
        }
        if !settled {
            XCTFail("The scenario's state machines did not settle: \(settleReport(capture))", file: file, line: line)
        }
    }

    private func isSettled(_ capture: CapturingLoggingPlugin) -> Bool {
        let tracked = tracked
        let lines = capture.lines
        return tracked.allSatisfy { $0.auth.runningActions == 0 && $0.credentialStore.runningActions == 0 }
            && Self.count(Self.authStateLine, in: lines) == tracked.map(\.auth.publishedStates).reduce(0, +)
            && Self.count(Self.credentialStoreStateLine, in: lines)
            == tracked.map(\.credentialStore.publishedStates).reduce(0, +)
    }

    private func settleReport(_ capture: CapturingLoggingPlugin) -> String {
        let tracked = tracked
        let lines = capture.lines
        let running = tracked.map { $0.auth.runningActions + $0.credentialStore.runningActions }
        let authPublished = tracked.map(\.auth.publishedStates).reduce(0, +)
        let credentialStorePublished = tracked.map(\.credentialStore.publishedStates).reduce(0, +)
        return "running actions \(running); auth states published \(authPublished), logged "
            + "\(Self.count(Self.authStateLine, in: lines)); credential store states published "
            + "\(credentialStorePublished), logged \(Self.count(Self.credentialStoreStateLine, in: lines))"
    }

    private static func count(_ prefix: String, in lines: [CapturingLoggingPlugin.Line]) -> Int {
        lines.count(where: { $0.message.hasPrefix(prefix) })
    }
}

/// A credentials client that starts empty: loading the session fails with `loadError`, everything else
/// succeeds.
struct TranscriptCredentialsClient: CredentialStoreStateBehavior {
    let loadError: EngineCredentialStoreError

    func fetchData(type: CredentialStoreDataType) async throws -> CredentialStoreData {
        switch type {
        case .amplifyCredentials:
            throw loadError
        case .deviceMetadata(let username):
            return .deviceMetadata(.noData, username)
        case .asfDeviceId(let username):
            return .asfDeviceId("transcript-asf-device-id", username)
        }
    }

    func storeData(data: CredentialStoreData) async throws {}

    func deleteData(type: CredentialStoreDataType) async throws {}
}

// MARK: Capturing logging plugin

/// Records every line with the scope it was logged at: which `Amplify.Logging` entry point resolved the
/// logger (`shape`), the category, the namespace, and the level.
final class CapturingLoggingPlugin: LoggingCategoryPlugin, @unchecked Sendable {

    struct Line: Codable, Hashable, Comparable, CustomStringConvertible {
        let shape: String
        let category: String?
        let namespace: String?
        let level: String
        let message: String

        static func < (lhs: Line, rhs: Line) -> Bool { lhs.description < rhs.description }

        var description: String {
            "[\(level)] \(shape)(\(category ?? "-"), \(namespace ?? "-")) \(message)"
        }
    }

    private let lock = NSLock()
    private var recorded: [Line] = []

    let key = "M2TranscriptCapturingLoggingPlugin"

    var lines: [Line] {
        lock.lock()
        defer { lock.unlock() }
        return recorded
    }

    func clear() {
        lock.lock()
        recorded.removeAll()
        lock.unlock()
    }

    private var waiters: [(condition: @Sendable () -> Bool, met: XCTestExpectation)] = []
    private var recordHook: (@Sendable (Line) -> Void)?

    /// Called with every line, on the logging thread, after the line is recorded.
    func onRecord(_ hook: (@Sendable (Line) -> Void)?) {
        lock.withLock { recordHook = hook }
    }

    /// Waits until `condition` holds. It is checked now, after every recorded line and on every
    /// `recheckWaiters()`, so the wait ends as soon as it holds. `timeout` only bounds a condition that
    /// never holds; the result is whether it held.
    func waitUntil(timeout: TimeInterval, _ condition: @escaping @Sendable () -> Bool) async -> Bool {
        let met = XCTestExpectation(description: "Capture condition met")
        met.assertForOverFulfill = false
        lock.withLock { waiters.append((condition, met)) }
        recheckWaiters()
        let result = await XCTWaiter.fulfillment(of: [met], timeout: timeout)
        lock.withLock { waiters.removeAll { $0.met === met } }
        return result == .completed
    }

    /// Checks the waiting conditions. Conditions read the capture, so they run outside its lock.
    func recheckWaiters() {
        let current = lock.withLock { waiters }
        for waiter in current where waiter.condition() {
            waiter.met.fulfill()
        }
    }

    fileprivate func record(_ line: Line) {
        let hook = lock.withLock {
            recorded.append(line)
            return recordHook
        }
        hook?(line)
        recheckWaiters()
    }

    var `default`: Logger { CapturingLogger(plugin: self, shape: "default", category: nil, namespace: nil) }

    func logger(forCategory category: String, logLevel: LogLevel) -> Logger {
        CapturingLogger(plugin: self, shape: "category+level", category: category, namespace: nil)
    }

    func logger(forCategory category: String) -> Logger {
        CapturingLogger(plugin: self, shape: "category", category: category, namespace: nil)
    }

    func logger(forNamespace namespace: String) -> Logger {
        CapturingLogger(plugin: self, shape: "namespace", category: nil, namespace: namespace)
    }

    func logger(forCategory category: String, forNamespace namespace: String) -> Logger {
        CapturingLogger(plugin: self, shape: "category+namespace", category: category, namespace: namespace)
    }

    func enable() {}
    func disable() {}
    func configure(using configuration: Any?) throws {}
    func reset() async {}
}

private struct CapturingLogger: Logger {
    let plugin: CapturingLoggingPlugin
    let shape: String
    let category: String?
    let namespace: String?

    var logLevel: Amplify.LogLevel {
        get { .verbose }
        set {}
    }

    private func record(_ level: String, _ message: String) {
        plugin.record(.init(shape: shape, category: category, namespace: namespace, level: level, message: message))
    }

    func error(_ message: @autoclosure () -> String) { record("error", message()) }
    func error(error: Error) { record("error(error:)", "\(error)") }
    func warn(_ message: @autoclosure () -> String) { record("warn", message()) }
    func info(_ message: @autoclosure () -> String) { record("info", message()) }
    func debug(_ message: @autoclosure () -> String) { record("debug", message()) }
    func verbose(_ message: @autoclosure () -> String) { record("verbose", message()) }
}

private extension Array where Element: Hashable {
    /// The elements of `self` not matched one-for-one in `other` (multiset difference).
    func difference(_ other: [Element]) -> [Element] {
        var remaining = Dictionary(other.map { ($0, 1) }, uniquingKeysWith: +)
        return filter { element in
            if let count = remaining[element], count > 0 {
                remaining[element] = count - 1
                return false
            }
            return true
        }
    }
}
