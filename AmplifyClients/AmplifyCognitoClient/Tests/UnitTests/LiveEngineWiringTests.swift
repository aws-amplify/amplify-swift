//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentity
import AWSCognitoIdentityProvider
import Foundation
import InternalAWSCognitoAuth
import SmithyHTTPAPI
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// How the live engine is wired in: the `.live` dependencies, the stateless revoker, the real
/// SDK clients underneath (user agent and error decoding), and the public API over the live engine.
final class LiveEngineWiringTests: XCTestCase {

    // MARK: The live dependencies

    /// `.live` builds the real engine and the real revoker.
    ///
    /// - Given: the live dependencies
    /// - When:
    ///    - an engine and a revoker are made
    /// - Then:
    ///    - they are `LiveSessionEngine` and `LiveSessionRevoker`, over the context's own SDK clients
    ///
    func testLiveDependenciesBuildTheRealEngineAndRevoker() throws {
        let clients = try CognitoServiceClients(configuration: ClientFixtures.configuration, configureUserPoolClient: nil)
        let context = SessionEngineContext(
            sessionId: .default,
            configuration: ClientFixtures.configuration,
            namespace: StorageFixtures.namespace,
            clients: clients
        )

        let engine = try SessionCoreDependencies.live.makeEngine(context)
        let revoker = SessionCoreDependencies.live.makeRevoker(ClientFixtures.configuration)

        let live = try XCTUnwrap(engine as? LiveSessionEngine)
        XCTAssertTrue(live.resources.clients.userPool === clients.userPool)
        XCTAssertTrue(revoker is LiveSessionRevoker)
    }

    // MARK: The stateless revoker

    /// The revoker runs the live revoke with inert device records: it revokes, and keeps nothing.
    ///
    /// - Given: a revoker over scripted Cognito, and a signed-in payload
    /// - When:
    ///    - it revokes the payload, and its device records are written and read back
    /// - Then:
    ///    - the only call is `RevokeToken` with the refresh token, never global; the outcome is complete
    ///    - its device records keep nothing: a written ASF ID reads back absent
    ///
    func testTheRevokerRevokesAndKeepsNothing() async throws {
        let harness = LiveEngineHarness()
        let payload = try await harness.signedInPayload(on: harness.engine())
        harness.cognito.clearCalls()
        harness.scriptSignOut()
        let resources = try LiveSessionRevoker.resources(
            configuration: harness.configuration,
            clients: CognitoServiceClients(configuration: harness.configuration, configureUserPoolClient: nil),
            services: EngineServices(userPool: ScriptedUserPool(cognito: harness.cognito), identity: nil)
        )
        let revoker = LiveSessionRevoker(resources: resources)

        let outcome = try await revoker.revoke(payload)

        XCTAssertEqual(outcome, .complete)
        XCTAssertEqual(harness.cognito.operations, ["RevokeToken"])
        XCTAssertEqual(harness.cognito.inputs("RevokeToken", as: RevokeTokenInput.self).first?.token, "refresh-alice-v1")
        harness.cognito.assertConsumed()
        try await resources.devices.saveASFDeviceId("asf-id", for: "alice")
        let read = try await resources.devices.asfDeviceId(for: "alice")
        XCTAssertEqual(read, .absent)
    }

    // MARK: The real SDK clients underneath

    /// Through the real SDK client: every request carries the Amplify user agent, and a Cognito error
    /// response is decoded and mapped as the plugin's is.
    ///
    /// - Given: an engine over the session's real SDK clients, whose HTTP engine records each request and
    ///   answers it with Cognito's `NotAuthorizedException` response
    /// - When:
    ///    - alice signs in with `USER_PASSWORD_AUTH`
    /// - Then:
    ///    - the sign-in throws `.notAuthorized` with Cognito's message
    ///    - the one request's `User-Agent` carries the `lib/amplify-swift` and `md/amplify-cognito` tokens
    ///
    func testRequestsGoThroughTheSessionsSDKClientsWithTheUserAgent() async throws {
        let http = CognitoErrorHTTPClient(errorType: "NotAuthorizedException", message: "Incorrect username or password.")
        let configuration = ClientFixtures.userPoolOnlyConfiguration
        let clients = try CognitoServiceClients(
            configuration: configuration,
            configureUserPoolClient: nil,
            baseHTTPClientEngine: http
        )
        // The device records are in memory (the test runner has no keychain entitlement); the Cognito
        // calls go through the session's real SDK clients, since no services are scripted.
        let keychain = TestKeychain()
        let engine = LiveSessionEngine(resources: EngineResources(
            authConfiguration: AuthConfiguration(client: configuration),
            clients: clients,
            devices: DeviceRecordIO(store: keychain.deviceStore(for: SessionStorageNamespace(
                pools: configuration.poolNamespace,
                accessGroup: nil
            ))),
            analytics: LazyUserPoolAnalytics(pinpointAppId: nil)
        ))

        await assertThrowsAsync({ try await engine.signIn(.flow(.userPassword), current: nil) }) { error in
            guard case .notAuthorized(let description, _, _) = authError(error) else {
                return XCTFail("expected notAuthorized, got \(error)")
            }
            XCTAssertTrue(description.contains("Incorrect username or password."), description)
        }
        XCTAssertEqual(http.userAgents.count, 1, "one InitiateAuth, then the mapped failure")
        let userAgent = try XCTUnwrap(http.userAgents.first ?? nil)
        XCTAssertTrue(userAgent.contains("lib/amplify-swift#"), userAgent)
        XCTAssertTrue(userAgent.contains("md/amplify-cognito"), userAgent)
    }

    // MARK: The public API over the live engine

    /// The public operations over the live engine and scripted Cognito, end to end.
    ///
    /// - Given: a client whose engine is the live engine over scripted Cognito
    /// - When:
    ///    - alice signs in, the session is fetched, and she signs out
    /// - Then:
    ///    - the sign-in is `.done`, the state is `.signedIn(alice)`, and the stored record names her
    ///    - the session's fields hold her tokens, identity and AWS credentials
    ///    - the sign-out revokes her refresh token, and the row is kept, signed out
    ///
    func testThePublicOperationsOverTheLiveEngine() async throws {
        let harness = LiveEngineHarness()
        let clientHarness = ClientHarness()
        let base = clientHarness.dependencies
        let dependencies = SessionCoreDependencies(
            registry: base.registry,
            gates: base.gates,
            makeStore: base.makeStore,
            makeClients: base.makeClients,
            makeEngine: { _ in try harness.engine() },
            makeRevoker: base.makeRevoker,
            scheduleRestore: base.scheduleRestore,
            bounds: base.bounds,
            now: { Date() }
        )
        let client = try AmplifyCognitoClient(
            configuration: ClientFixtures.configuration,
            options: .init(sessionId: ClientFixtures.id("work")),
            dependencies: dependencies
        )
        harness.scriptSRP()
        harness.scriptIdentityPool()
        harness.scriptSignOut()

        let signIn = try await client.signIn(username: "alice", password: "password")
        let state = await client.currentSessionState()
        let session = try await client.fetchAuthSession()
        let record = try clientHarness.storedRecord(ClientFixtures.id("work"))
        let signOut = try await client.signOut()
        let afterSignOut = try clientHarness.storedRecord(ClientFixtures.id("work"))

        XCTAssertEqual(signIn.nextStep, .done)
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")))
        XCTAssertEqual(record?.username, "alice")
        XCTAssertEqual(record?.kind, .userPoolAndIdentityPool)
        XCTAssertEqual(try session.identityIdResult.get(), LiveEngineFixtures.identityId)
        XCTAssertEqual(try session.awsCredentialsResult.get().accessKeyId, "AKID-v1")
        XCTAssertEqual(try session.userPoolTokensResult.get().refreshToken, "refresh-alice-v1")
        XCTAssertEqual(signOut, .complete)
        XCTAssertEqual(harness.cognito.inputs("RevokeToken", as: RevokeTokenInput.self).first?.token, "refresh-alice-v1")
        harness.cognito.assertConsumed()
        XCTAssertNotNil(afterSignOut)
        XCTAssertEqual(afterSignOut?.kind, SessionKind.signedOut)
        let finalState = await client.currentSessionState()
        XCTAssertEqual(finalState, .signedOut)
    }
}

/// Answers every request with a Cognito JSON error, and records each request's `User-Agent`.
///
/// - Note: `@unchecked Sendable`: `recorded` is only touched while holding `lock`.
private final class CognitoErrorHTTPClient: HTTPClient, @unchecked Sendable {

    let errorType: String
    let message: String
    private let lock = NSLock()
    private var recorded: [String?] = []

    init(errorType: String, message: String) {
        self.errorType = errorType
        self.message = message
    }

    var userAgents: [String?] {
        lock.lock()
        defer { lock.unlock() }
        return recorded
    }

    func send(request: SmithyHTTPAPI.HTTPRequest) async throws -> SmithyHTTPAPI.HTTPResponse {
        record(request.headers.value(for: "User-Agent"))
        let body = #"{"__type":"\#(errorType)","message":"\#(message)"}"#
        return HTTPResponse(
            headers: Headers(["Content-Type": "application/x-amz-json-1.1", "X-Amzn-ErrorType": errorType]),
            body: .data(Data(body.utf8)),
            statusCode: .badRequest
        )
    }

    private func record(_ userAgent: String?) {
        lock.lock()
        recorded.append(userAgent)
        lock.unlock()
    }
}
