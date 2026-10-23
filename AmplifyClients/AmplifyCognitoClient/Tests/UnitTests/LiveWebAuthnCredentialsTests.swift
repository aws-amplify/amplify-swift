//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation
import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// WebAuthn credential list and delete over the live engine and scripted Cognito: the Cognito requests list
/// and delete send, the page they return, and how each failure reaches the caller.
final class LiveWebAuthnCredentialsTests: XCTestCase {

    private var harness: LiveEngineHarness!
    private var clientHarness: ClientHarness!
    private let created = Date(timeIntervalSince1970: 1_700_000_000)

    override func setUp() {
        harness = LiveEngineHarness()
        clientHarness = ClientHarness()
    }

    override func tearDown() async throws {
        harness.cognito.assertConsumed()
        await clientHarness.waitForBaseline()
        harness = nil
        clientHarness = nil
    }

    // MARK: Requests and pages

    /// - Given: alice signed in through a client over the live engine, and Cognito holding three passkeys, one
    ///   with an empty friendly name, plus three entries missing a required field
    /// - When:
    ///    - she lists a page of 2, then the next page with the first result's token, then deletes a credential
    /// - Then:
    ///    - each request carries her access token as the session holds it, `MaxResults` 2 and the token, or the
    ///      credential's identifier; nothing is refreshed and the session record is unchanged
    ///    - the pages hold the three complete credentials, the empty name as `nil`, and the tokens Cognito gave
    func testListPagesAndDeleteSendAliceTokenAsItIs() async throws {
        let client = try liveClient("work")
        try await signIn(client, "alice")
        let before = try clientHarness.storedRecord(ClientFixtures.id("work"))
        harness.cognito.once("ListWebAuthnCredentials") { (_: ListWebAuthnCredentialsInput) in
            ListWebAuthnCredentialsOutput(
                credentials: [
                    Self.description("cred-1", name: "Phone"),
                    Self.description(nil, name: "no id"),
                    Self.description("cred-2", name: "")
                ],
                nextToken: "page-2"
            )
        }
        harness.cognito.once("ListWebAuthnCredentials") { (_: ListWebAuthnCredentialsInput) in
            ListWebAuthnCredentialsOutput(
                credentials: [
                    Self.description("cred-3", name: nil),
                    Self.description("no-date", name: "x", createdAt: nil),
                    Self.description("no-rp", name: "x", relyingPartyId: nil)
                ],
                nextToken: nil
            )
        }
        harness.cognito.once("DeleteWebAuthnCredential") { (_: DeleteWebAuthnCredentialInput) in
            DeleteWebAuthnCredentialOutput()
        }

        let first = try await client.listWebAuthnCredentials(options: .init(pageSize: 2))
        let second = try await client.listWebAuthnCredentials(options: .init(pageSize: 2, nextToken: first.nextToken))
        try await client.deleteWebAuthnCredential(credentialId: "cred-2")

        let token = LiveEngineFixtures.jwt("alice", use: "access")
        let lists = harness.cognito.inputs("ListWebAuthnCredentials", as: ListWebAuthnCredentialsInput.self)
        XCTAssertEqual(lists.map(\.accessToken), [token, token])
        XCTAssertEqual(lists.map(\.maxResults), [2, 2])
        XCTAssertEqual(lists.map(\.nextToken), [nil, "page-2"])
        let deletes = harness.cognito.inputs("DeleteWebAuthnCredential", as: DeleteWebAuthnCredentialInput.self)
        XCTAssertEqual(deletes.map(\.accessToken), [token])
        XCTAssertEqual(deletes.map(\.credentialId), ["cred-2"])
        XCTAssertEqual(first, AuthClientListWebAuthnCredentialsResult(
            credentials: [credential("cred-1", name: "Phone"), credential("cred-2", name: nil)],
            nextToken: "page-2"
        ))
        XCTAssertEqual(second, AuthClientListWebAuthnCredentialsResult(credentials: [credential("cred-3", name: nil)], nextToken: nil))
        XCTAssertFalse(harness.cognito.operations.contains("GetTokensFromRefreshToken"))
        XCTAssertEqual(try clientHarness.storedRecord(ClientFixtures.id("work")), before)
    }

    /// - Given: alice signed in on `work` and bob on `home`, each over its own live engine
    /// - When: each lists, and each deletes
    /// - Then:
    ///    - every request from `work` carries only alice's access token, and every one from `home` only bob's
    func testEachSessionSendsOnlyItsOwnAccessToken() async throws {
        let work = try liveClient("work")
        let home = try liveClient("home")
        try await signIn(work, "alice")
        try await signIn(home, "bob")
        harness.cognito.always("ListWebAuthnCredentials") { (_: ListWebAuthnCredentialsInput) in
            ListWebAuthnCredentialsOutput(credentials: [], nextToken: nil)
        }
        harness.cognito.always("DeleteWebAuthnCredential") { (_: DeleteWebAuthnCredentialInput) in
            DeleteWebAuthnCredentialOutput()
        }

        _ = try await work.listWebAuthnCredentials()
        _ = try await home.listWebAuthnCredentials()
        try await work.deleteWebAuthnCredential(credentialId: "alice-cred")
        try await home.deleteWebAuthnCredential(credentialId: "bob-cred")

        let alice = LiveEngineFixtures.jwt("alice", use: "access")
        let bob = LiveEngineFixtures.jwt("bob", use: "access")
        XCTAssertEqual(harness.cognito.inputs("ListWebAuthnCredentials", as: ListWebAuthnCredentialsInput.self).map(\.accessToken), [alice, bob])
        let deletes = harness.cognito.inputs("DeleteWebAuthnCredential", as: DeleteWebAuthnCredentialInput.self)
        XCTAssertEqual(deletes.map(\.accessToken), [alice, bob])
        XCTAssertEqual(deletes.map(\.credentialId), ["alice-cred", "bob-cred"])
    }

    // MARK: Errors

    /// Cognito's WebAuthn exceptions are `.service` with their code, one to one.
    ///
    /// - Given: the live engine and a signed-in payload
    /// - When: Cognito answers list and delete with each of the seven WebAuthn exceptions
    /// - Then:
    ///    - each call throws `.service` with the matching code and the engine's description, the plugin's
    func testTheWebAuthnExceptionsAreServiceErrorsWithTheirCode() async throws {
        let engine = try harness.engine()
        let payload = try await harness.signedInPayload("alice", on: engine)
        let cases: [(Error, AuthClientServiceErrorCode)] = [
            (WebAuthnNotEnabledException(message: "m"), .webAuthnNotEnabled),
            (WebAuthnCredentialNotSupportedException(message: "m"), .webAuthnNotSupported),
            (WebAuthnConfigurationMissingException(message: "m"), .webAuthnConfigurationMissing),
            (WebAuthnChallengeNotFoundException(message: "m"), .webAuthnChallengeNotFound),
            (WebAuthnClientMismatchException(message: "m"), .webAuthnClientMismatch),
            (WebAuthnOriginNotAllowedException(message: "m"), .webAuthnOriginNotAllowed),
            (WebAuthnRelyingPartyMismatchException(message: "m"), .webAuthnRelyingPartyMismatch)
        ]

        for (exception, code) in cases {
            let thrown = UncheckedError(exception)
            harness.cognito.once("ListWebAuthnCredentials") { (_: ListWebAuthnCredentialsInput) -> ListWebAuthnCredentialsOutput in
                throw thrown.error
            }
            harness.cognito.once("DeleteWebAuthnCredential") { (_: DeleteWebAuthnCredentialInput) -> DeleteWebAuthnCredentialOutput in
                throw thrown.error
            }
            await assertThrowsAsync({ try await engine.listWebAuthnCredentials(payload, pageSize: 20, nextToken: nil) }) { error in
                guard case .service(let got, let description, _, _) = authError(error) else {
                    return XCTFail("\(code): \(error)")
                }
                XCTAssertEqual(got, code)
                XCTAssertEqual(description, (exception as? EngineAuthErrorConvertible)?.engineError.errorDescription)
            }
            await assertThrowsAsync({ try await engine.deleteWebAuthnCredential(payload, credentialId: "cred-1") }) { error in
                XCTAssertEqual(authError(error)?.kind, .service(code), "\(error)")
            }
        }
    }

    /// Deleting a credential Cognito does not know, and a token Cognito refuses.
    ///
    /// - Given: the live engine and a signed-in payload
    /// - When: Cognito answers a delete with `ResourceNotFoundException`, and a list with `NotAuthorizedException`
    /// - Then:
    ///    - the delete throws `.service(.resourceNotFound)` and the list `.notAuthorized`, as the plugin maps them
    func testAnUnknownCredentialAndARefusedTokenMapAsThePlugins() async throws {
        let engine = try harness.engine()
        let payload = try await harness.signedInPayload("alice", on: engine)
        harness.cognito.once("DeleteWebAuthnCredential") { (_: DeleteWebAuthnCredentialInput) -> DeleteWebAuthnCredentialOutput in
            throw ResourceNotFoundException(message: "not found")
        }
        harness.cognito.once("ListWebAuthnCredentials") { (_: ListWebAuthnCredentialsInput) -> ListWebAuthnCredentialsOutput in
            throw NotAuthorizedException(message: "Access Token has been revoked")
        }

        await assertThrowsAsync({ try await engine.deleteWebAuthnCredential(payload, credentialId: "gone") }) { error in
            XCTAssertEqual(authError(error)?.kind, .service(.resourceNotFound), "\(error)")
        }
        await assertThrowsAsync({ try await engine.listWebAuthnCredentials(payload, pageSize: 20, nextToken: nil) }) { error in
            guard case .notAuthorized(let description, _, _) = authError(error) else {
                return XCTFail("\(error)")
            }
            XCTAssertEqual(description, "Access Token has been revoked")
        }
    }

    /// - Given: the live engine and a signed-in payload
    /// - When: Cognito's call fails with an error the engine does not know
    /// - Then:
    ///    - list and delete throw the plugin's unknown-service error, naming the operation
    func testAnUnknownFailureIsThePluginsUnknownServiceError() async throws {
        let engine = try harness.engine()
        let payload = try await harness.signedInPayload("alice", on: engine)
        harness.cognito.once("ListWebAuthnCredentials") { (_: ListWebAuthnCredentialsInput) -> ListWebAuthnCredentialsOutput in
            throw FixtureError(description: "boom")
        }
        harness.cognito.once("DeleteWebAuthnCredential") { (_: DeleteWebAuthnCredentialInput) -> DeleteWebAuthnCredentialOutput in
            throw FixtureError(description: "boom")
        }

        await assertThrowsAsync({ try await engine.listWebAuthnCredentials(payload, pageSize: 20, nextToken: nil) }) { error in
            guard case .service(nil, let description, _, _) = authError(error) else {
                return XCTFail("\(error)")
            }
            XCTAssertEqual(description, "An unknown error type was thrown by the service. Unable to list WebAuthn credentials.")
        }
        await assertThrowsAsync({ try await engine.deleteWebAuthnCredential(payload, credentialId: "cred-1") }) { error in
            guard case .service(nil, let description, _, _) = authError(error) else {
                return XCTFail("\(error)")
            }
            XCTAssertEqual(description, "An unknown error type was thrown by the service. Unable to delete WebAuthn credential.")
        }
    }

    /// A cancelled call is cancellation, never `.service`.
    ///
    /// - Given: the live engine and a signed-in payload
    /// - When: Cognito's call throws `CancellationError`, which the engine reports as the plugin always has,
    ///   `.service(unknown)` with the `CancellationError` underneath
    /// - Then:
    ///    - list and delete throw `CancellationError`
    func testACancelledCognitoCallIsCancellation() async throws {
        let engine = try harness.engine()
        let payload = try await harness.signedInPayload("alice", on: engine)
        harness.cognito.once("ListWebAuthnCredentials") { (_: ListWebAuthnCredentialsInput) -> ListWebAuthnCredentialsOutput in
            throw CancellationError()
        }
        harness.cognito.once("DeleteWebAuthnCredential") { (_: DeleteWebAuthnCredentialInput) -> DeleteWebAuthnCredentialOutput in
            throw CancellationError()
        }

        await assertThrowsAsync({ try await engine.listWebAuthnCredentials(payload, pageSize: 20, nextToken: nil) }) { error in
            XCTAssertTrue(error is CancellationError, "\(error)")
        }
        await assertThrowsAsync({ try await engine.deleteWebAuthnCredential(payload, credentialId: "cred-1") }) { error in
            XCTAssertTrue(error is CancellationError, "\(error)")
        }
    }

    /// - Given: a client over the live engine, signed in, whose Cognito list call waits
    /// - When: the calling task is cancelled while the call waits, and the call then fails as a cancelled
    ///   URL load does (`URLError.cancelled`)
    /// - Then:
    ///    - the caller gets `CancellationError`, not `.service`, and the session is still signed in
    func testCancellingTheCallerIsCancellation() async throws {
        let client = try liveClient("work")
        try await signIn(client, "alice")
        let arrived = Gate(isOpen: true)
        let release = Gate()
        harness.cognito.once("ListWebAuthnCredentials") { (_: ListWebAuthnCredentialsInput) -> ListWebAuthnCredentialsOutput in
            await arrived.pass()
            await release.pass()
            throw URLError(.cancelled)
        }

        let call = Task { try await client.listWebAuthnCredentials() }
        await arrived.waitForArrivals(1)
        call.cancel()
        await release.open()

        await assertThrowsAsync({ try await call.value }) { error in
            XCTAssertTrue(error is CancellationError, "\(error)")
        }
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedIn(AuthClientUser(username: "alice", userId: "sub-alice")))
    }

    /// - Given: the live engine
    /// - When: list and delete get a payload with no user pool tokens, and list a negative page size
    /// - Then:
    ///    - the first two throw `notSignedIn`, the third `validation(field: "pageSize")`, and no request is sent
    func testThePayloadAndThePageSizeAreCheckedBeforeAnyRequest() async throws {
        let engine = try harness.engine()
        let guest = try EnginePayloadFixtures.data("identityPoolOnly")
        let payload = try EnginePayloadFixtures.data("userPoolOnly")

        await assertThrowsAsync({ try await engine.listWebAuthnCredentials(guest, pageSize: 20, nextToken: nil) }) { error in
            XCTAssertEqual(authError(error)?.kind, .notSignedIn, "\(error)")
        }
        await assertThrowsAsync({ try await engine.deleteWebAuthnCredential(guest, credentialId: "cred-1") }) { error in
            XCTAssertEqual(authError(error)?.kind, .notSignedIn, "\(error)")
        }
        await assertThrowsAsync({ try await engine.listWebAuthnCredentials(payload, pageSize: -1, nextToken: nil) }) { error in
            XCTAssertEqual(authError(error)?.kind, .validation(field: "pageSize"), "\(error)")
        }
        XCTAssertEqual(harness.cognito.operations, [])
    }

    /// The error rule on its own.
    ///
    /// - Given: the errors list and delete can see
    /// - When: each is mapped, with the calling task cancelled or not
    /// - Then:
    ///    - a cancelled task, a `CancellationError`, and a `.service` with one underneath are
    ///      `CancellationError`; any other engine error is `AuthClientError(engine:)`; anything else is
    ///      unchanged
    func testTheFailureRule() {
        let cancelledService = WebAuthnError.unknown(message: "m", error: CancellationError()).engineError
        let notEnabled = WebAuthnNotEnabledException(message: "m").engineError
        let other = FixtureError(description: "other")

        XCTAssertTrue(LiveSessionEngine.signedInFailure(cancelledService, cancelled: false) is CancellationError)
        XCTAssertTrue(LiveSessionEngine.signedInFailure(CancellationError(), cancelled: false) is CancellationError)
        XCTAssertTrue(LiveSessionEngine.signedInFailure(notEnabled, cancelled: true) is CancellationError)
        XCTAssertEqual(authError(LiveSessionEngine.signedInFailure(notEnabled, cancelled: false))?.kind, .service(.webAuthnNotEnabled))
        XCTAssertTrue(LiveSessionEngine.signedInFailure(other, cancelled: false) is FixtureError)
    }

    // MARK: Support

    /// A client over the live engine, sharing this test's scripted Cognito with every other such client.
    private func liveClient(_ name: String) throws -> AmplifyCognitoClient {
        let base = clientHarness.dependencies
        let harness = harness!
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
        return try AmplifyCognitoClient(
            configuration: ClientFixtures.configuration,
            options: .init(sessionId: ClientFixtures.id(name)),
            dependencies: dependencies
        )
    }

    private func signIn(_ client: AmplifyCognitoClient, _ username: String) async throws {
        harness.scriptSRP(username)
        harness.scriptIdentityPool()
        let result = try await client.signIn(username: username, password: "password")
        XCTAssertEqual(result.nextStep, .done)
    }

    private static func description(
        _ credentialId: String?,
        name: String?,
        createdAt: Date? = Date(timeIntervalSince1970: 1_700_000_000),
        relyingPartyId: String? = "rp.example"
    ) -> CognitoIdentityProviderClientTypes.WebAuthnCredentialDescription {
        CognitoIdentityProviderClientTypes.WebAuthnCredentialDescription(
            authenticatorTransports: ["internal"],
            createdAt: createdAt,
            credentialId: credentialId,
            friendlyCredentialName: name,
            relyingPartyId: relyingPartyId
        )
    }

    private func credential(_ credentialId: String, name: String?) -> AuthClientWebAuthnCredential {
        AuthClientWebAuthnCredential(credentialId: credentialId, createdAt: created, relyingPartyId: "rp.example", friendlyName: name)
    }
}

/// An error handed to a `@Sendable` script. The SDK's exception types are not `Sendable`.
private struct UncheckedError: @unchecked Sendable {
    let error: Error

    init(_ error: Error) {
        self.error = error
    }
}
