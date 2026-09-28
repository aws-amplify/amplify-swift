//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import AuthenticationServices
#endif
import AmplifyKeychainTestCommon
import AWSCognitoIdentityProvider
import Foundation
import XCTest
@testable import Amplify
@_spi(KeychainStore) import AWSPluginsCore
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// Site-level coverage for the static engine log sites.
///
/// The log-transcript gate's transcript has no lines for four of the seven static-site groups (`HostedUISignInHelper`,
/// `PlatformWebAuthnCredentials`, `AWSCognitoAuthCredentialStore`, `MFAType`), and the golden transcript is
/// locked. So each test here drives one site through its real call path, with the production router
/// (`AmplifyEngineLogRouter()`) installed as the global router and a capturing `Amplify.Logging` plugin,
/// and asserts what reached `Amplify.Logging`:
/// - the entry point that resolved the logger and its category and namespace, compared with the resolution
///   the site had before the engine got its own logging, computed from the type
///   (`String(describing: Type.self)`, and `CategoryType.auth.displayName` for the sites that log under the
///   auth category), never with a second copy of the site's literal;
/// - the Amplify logger method (`error`, `error(error:)`, `verbose`, …) and the message.
final class EngineStaticLogSiteTests: XCTestCase, @unchecked Sendable {

    private var capture: CapturingLoggingPlugin!
    private var savedPlugins: [PluginKey: LoggingCategoryPlugin] = [:]
    private var savedLogLevel: Amplify.LogLevel = .error
    private var savedRouter: (any EngineLogRouter)?

    override func setUp() async throws {
        capture = CapturingLoggingPlugin()
        savedPlugins = Amplify.Logging.plugins
        savedLogLevel = Amplify.Logging.logLevel
        savedRouter = EngineLog.router
        Amplify.Logging.plugins = [capture.key: capture]
        Amplify.Logging.logLevel = .verbose
        EngineLog.install(AmplifyEngineLogRouter())
    }

    override func tearDown() async throws {
        // Every line these tests check is logged before the call they await returns, and none of them
        // sends an event to a state machine, so nothing is left to log once a test ends.
        Amplify.Logging.plugins = savedPlugins
        Amplify.Logging.logLevel = savedLogLevel
        if let savedRouter {
            EngineLog.install(savedRouter)
        }
    }

    // MARK: Previous resolutions

    /// `DefaultLogger`'s default: `Amplify.Logging.logger(forCategory: String(describing: self))`.
    private func shapeB(_ type: Any.Type) -> (shape: String, category: String?, namespace: String?) {
        ("category", String(describing: type), nil)
    }

    /// The auth-category override: `logger(forCategory: CategoryType.auth.displayName, forNamespace: String(describing: self))`.
    private func shapeA(_ type: Any.Type) -> (shape: String, category: String?, namespace: String?) {
        ("category+namespace", CategoryType.auth.displayName, String(describing: type))
    }

    private func lines(
        at scope: (shape: String, category: String?, namespace: String?)
    ) -> [(level: String, message: String)] {
        capture.lines
            .filter { $0.shape == scope.shape && $0.category == scope.category && $0.namespace == scope.namespace }
            .map { ($0.level, $0.message) }
    }

    private func assertLines(
        at scope: (shape: String, category: String?, namespace: String?),
        _ expected: [(level: String, message: String)],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let actual = lines(at: scope)
        XCTAssertEqual(actual.map(\.level), expected.map(\.level), "levels at \(scope)", file: file, line: line)
        XCTAssertEqual(actual.map(\.message), expected.map(\.message), "messages at \(scope)", file: file, line: line)
    }

    // MARK: Sites the log transcript does not cover

    /// Test that `MFAType(rawValue:)` logs an unsupported value at its previous scope
    ///
    /// - Given: A user pool whose `GetUser` lists an unknown MFA setting
    /// - When:
    ///    - `FetchMFAPreferenceTask.fetchMFAPreference(with:)` parses it (a production path to the initializer)
    /// - Then:
    ///    - One `error` line reaches `Amplify.Logging.logger(forCategory: "MFAType")`
    ///
    func testMFATypeInitializerLogsAtItsPreviousScope() async throws {
        let userPool = MockIdentityProvider(mockGetUserAttributeResponse: { _ in
            .init(userMFASettingList: ["X"])
        })
        let task = FetchMFAPreferenceTask(
            authStateMachine: Defaults.makeDefaultAuthStateMachine(),
            userPoolFactory: { userPool }
        )

        let preference = try await task.fetchMFAPreference(with: "access-token")

        XCTAssertNil(preference.enabled)
        assertLines(at: shapeB(MFAType.self), [
            ("error", "Tried to initialize an unsupported MFA type with value: X")
        ])
    }

    /// Test that the credential store logs at its previous scope
    ///
    /// - Given: A keychain holding only the Cognito client's default-session record
    /// - When:
    ///    - The plugin's credential store retrieves its credentials
    /// - Then:
    ///    - One `verbose` line reaches `Amplify.Logging.logger(forCategory: "AWSCognitoAuthCredentialStore")`
    ///
    func testCredentialStoreLogsAtItsPreviousScope() throws {
        let userPool = UserPoolConfigurationData(poolId: "us-east-1_Pool", clientId: "client", region: "us-east-1")
        let identityPool = IdentityPoolConfigurationData(poolId: "us-east-1:identity-pool", region: "us-east-1")
        let configuration = AuthConfiguration.userPoolsAndIdentityPools(userPool, identityPool)
        let keychain = InMemoryKeychain()
        let credentials = LongLivedCredentials.userPoolAndIdentityPool()
        _ = try CognitoClientRecords.writeDefaultSession(credentials, in: keychain, for: configuration)
        let store = AWSCognitoAuthCredentialStore(
            authConfiguration: configuration,
            keychain: InMemoryPluginKeychainStore(keychain: keychain)
        )

        XCTAssertEqual(try store.retrieveCredential(), credentials)
        assertLines(at: shapeB(AWSCognitoAuthCredentialStore.self), [
            ("verbose", "[AWSCognitoAuthCredentialStore] Read the session from the Cognito client's default session record")
        ])
    }

    #if os(iOS) || os(macOS) || os(visionOS)
    /// Test that `HostedUISignInHelper` logs at its previous scope
    ///
    /// - Given: A state machine with a user already signed in
    /// - When:
    ///    - `HostedUISignInHelper.initiateSignIn()` runs
    /// - Then:
    ///    - It throws, after one `verbose` line reaches
    ///      `Amplify.Logging.logger(forCategory: "Authentication", forNamespace: "HostedUISignInHelper")`
    ///
    func testHostedUISignInHelperLogsAtItsPreviousScope() async {
        let stateMachine = Defaults.makeDefaultAuthStateMachine(
            initialState: .configured(.signedIn(.testData), .configured, .notStarted)
        )
        let helper = HostedUISignInHelper(
            request: AuthWebUISignInRequest(presentationAnchor: nil, options: .init()),
            authstateMachine: stateMachine,
            configuration: Defaults.makeDefaultAuthConfigData()
        )

        do {
            _ = try await helper.initiateSignIn()
            XCTFail("Expected an invalid-state error")
        } catch {}

        assertLines(at: shapeA(HostedUISignInHelper.self), [("verbose", "Wait for a valid state")])
    }

    /// Test that a WebAuthn `error("", error)` line reaches Amplify's `error(error:)` at the previous scope
    ///
    /// - Given: The platform WebAuthn delegate, and a controller whose only request is not a WebAuthn one
    /// - When:
    ///    - The controller reports an error
    /// - Then:
    ///    - Three lines reach `Amplify.Logging.logger(forCategory: "PlatformWebAuthnCredentials")`, each
    ///      through `error(error:)` with the error itself, as `log.error(error:)` did before: the
    ///      reported error, then the assertion and registration errors the delegate resumes with
    ///
    func testWebAuthnErrorReachesErrorErrorAtItsPreviousScope() throws {
        guard #available(iOS 17.4, macOS 13.5, visionOS 1.0, *) else {
            throw XCTSkip("WebAuthn needs iOS 17.4 / macOS 13.5")
        }
        let credentials = PlatformWebAuthnCredentials(presentationAnchor: nil)
        let error = NSError(domain: "WebAuthnSiteTest", code: 7)

        credentials.authorizationController(
            controller: ASAuthorizationController(authorizationRequests: [ASAuthorizationAppleIDProvider().createRequest()]),
            didCompleteWithError: error
        )

        assertLines(at: shapeB(PlatformWebAuthnCredentials.self), [
            ("error(error:)", "\(error)"),
            ("error(error:)", "\(AuthError.unknown("Unable to assert WebAuthm Credential", error))"),
            ("error(error:)", "\(AuthError.unknown("Unable to register WebAuthm Credential", error))")
        ])
    }

    /// Test that a failed WebAuthn assertion logs both its lines at the previous scope
    ///
    /// - Given: The platform WebAuthn delegate, and a controller holding an assertion request
    /// - When:
    ///    - The controller reports an `ASAuthorizationError`
    /// - Then:
    ///    - `error(error:)` with the error, `verbose` "Unable to assert existing credential", and
    ///      `error(error:)` with the `WebAuthnError` the assertion resumes with, reach
    ///      `Amplify.Logging.logger(forCategory: "PlatformWebAuthnCredentials")`
    ///
    func testWebAuthnAssertionFailureLogsAtItsPreviousScope() throws {
        guard #available(iOS 17.4, macOS 13.5, visionOS 1.0, *) else {
            throw XCTSkip("WebAuthn needs iOS 17.4 / macOS 13.5")
        }
        let credentials = PlatformWebAuthnCredentials(presentationAnchor: nil)
        let request = ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: "example.com")
            .createCredentialAssertionRequest(challenge: Data("challenge".utf8))
        let error = ASAuthorizationError(.canceled)

        credentials.authorizationController(
            controller: ASAuthorizationController(authorizationRequests: [request]),
            didCompleteWithError: error
        )

        assertLines(at: shapeB(PlatformWebAuthnCredentials.self), [
            ("error(error:)", (error as NSError).description),
            ("verbose", "Unable to assert existing credential"),
            ("error(error:)", "\(WebAuthnError.assertionFailed(error: error))")
        ])
    }
    #endif

    // MARK: Sites the log transcript covers (their scope read from the site, not from a literal)

    /// Test that `AuthFactorType(rawValue:)` logs at its previous scope
    ///
    /// - Given: A stored `USER_AUTH` flow with an unknown preferred factor
    /// - When:
    ///    - It is decoded (`AuthFlowType.init(from:)`, the production path to the initializer)
    /// - Then:
    ///    - Decoding throws, after one `error` line reaches `Amplify.Logging.logger(forCategory: "AuthFactorType")`
    ///
    func testAuthFactorTypeInitializerLogsAtItsPreviousScope() {
        let json = Data(#"{"type":"USER_AUTH","preferredFirstFactor":"X"}"#.utf8)

        XCTAssertThrowsError(try JSONDecoder().decode(AuthFlowType.self, from: json))
        assertLines(at: shapeB(AuthFactorType.self), [
            ("error", "Tried to initialize an unsupported MFA type with value: X")
        ])
    }

    /// Test that `UserPoolSignInHelper` logs at its previous scope
    ///
    /// - Given: A sign-in state that has not started
    /// - When:
    ///    - `UserPoolSignInHelper.checkNextStep` inspects it
    /// - Then:
    ///    - One `verbose` line reaches `Amplify.Logging.logger(forCategory: "UserPoolSignInHelper")`
    ///
    func testUserPoolSignInHelperLogsAtItsPreviousScope() throws {
        let state = SignInState.notStarted

        XCTAssertNil(try UserPoolSignInHelper.checkNextStep(state))
        assertLines(at: shapeB(UserPoolSignInHelper.self), [("verbose", "Checking next step for: \(state)")])
    }

    /// Test that `FetchAuthSessionOperationHelper` without an environment logs at its previous scope
    ///
    /// - Given: A helper with no environment, as `AWSAuthTaskHelper` creates it
    /// - When:
    ///    - It builds a session result from a fetch error
    /// - Then:
    ///    - One `verbose` line reaches `Amplify.Logging.logger(forCategory: "FetchAuthSessionOperationHelper")`
    ///      through the global router
    ///
    func testFetchAuthSessionHelperWithoutEnvironmentLogsAtItsPreviousScope() async throws {
        let helper = FetchAuthSessionOperationHelper()
        let error = AuthorizationError.sessionError(.noIdentityPool, .userPoolOnly(signedInData: .testData))

        _ = try await helper.sessionResultWithError(error, authenticationState: .signedIn(.testData))

        assertLines(at: shapeB(FetchAuthSessionOperationHelper.self), [
            ("verbose", "Received fetch auth session error - \(error)")
        ])
    }
}
