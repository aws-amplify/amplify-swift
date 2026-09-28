//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyFoundation
import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// `listWebAuthnCredentials(options:)` and
/// `deleteWebAuthnCredential(credentialId:)` through the core, over the fake engine: what reaches the seam,
/// on which session, and what the core refuses first. `LiveWebAuthnCredentialsTests` covers the live engine.
final class WebAuthnCredentialsTests: XCTestCase {

    private var harness: ClientHarness!
    private let work = ClientFixtures.id("work")
    private let home = ClientFixtures.id("home")
    private let created = Date(timeIntervalSince1970: 1_700_000_000)

    override func setUp() {
        harness = ClientHarness()
    }

    override func tearDown() async throws {
        await harness.waitForBaseline()
        harness = nil
    }

    // MARK: Routing and mapping

    /// - Given: `work` signed in as alice and `home` as bob, whose tokens need a refresh, and `work`'s engine
    ///   answering a list with two credentials and a next token
    /// - When:
    ///    - `work` lists with a page size of 5 and a next token, and deletes a credential; `home` deletes one
    /// - Then:
    ///    - `work`'s engine receives the list and the delete with alice's payload and the arguments as given,
    ///      and refreshes nothing; `home`'s engine sees nothing of them, and bob is not refreshed by them
    ///    - `home`'s delete then refreshes bob once, on `home`'s engine, and sends bob's refreshed payload
    ///    - the page is mapped field for field, a `nil` friendly name stays `nil`, and the next token is kept
    ///    - `work`'s record is not written (bob's refresh writes only bob's)
    func testListAndDeleteRouteWithTheirSessionsPayload() async throws {
        let alice = FakePayload.signedIn("alice")
        let bob = FakePayload.signedIn("bob", stale: true)
        try harness.signIn(work, alice)
        try harness.signIn(home, bob)
        let client = try harness.client(work)
        let homeClient = try harness.client(home)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let other = try XCTUnwrap(harness.engine(for: home))
        let page = EngineWebAuthnCredentialPage(
            credentials: [
                EngineWebAuthnCredential(credentialId: "cred-1", createdAt: created, relyingPartyId: "rp.example", friendlyName: "Phone"),
                EngineWebAuthnCredential(credentialId: "cred-2", createdAt: created + 60, relyingPartyId: "rp.example", friendlyName: nil)
            ],
            nextToken: "page-2"
        )
        engine.scriptPhase5(.listWebAuthnCredentials) { _ in page }

        let result = try await client.listWebAuthnCredentials(options: .init(pageSize: 5, nextToken: "page-1"))
        try await client.deleteWebAuthnCredential(credentialId: "cred-1")
        XCTAssertEqual(other.refreshCalls, [], "work's calls refreshed bob")
        XCTAssertEqual(other.phase5Calls, [])
        try await homeClient.deleteWebAuthnCredential(credentialId: "cred-9")

        XCTAssertEqual(engine.phase5Calls, [
            .listWebAuthnCredentials(payload: alice.data, pageSize: 5, nextToken: "page-1"),
            .deleteWebAuthnCredential(payload: alice.data, credentialId: "cred-1")
        ])
        XCTAssertEqual(engine.refreshCalls, [])
        XCTAssertEqual(other.refreshCalls, [bob.data])
        XCTAssertEqual(other.phase5Calls, [.deleteWebAuthnCredential(payload: bob.refreshed.data, credentialId: "cred-9")])
        XCTAssertEqual(result, AuthClientListWebAuthnCredentialsResult(
            credentials: [
                AuthClientWebAuthnCredential(credentialId: "cred-1", createdAt: created, relyingPartyId: "rp.example", friendlyName: "Phone"),
                AuthClientWebAuthnCredential(credentialId: "cred-2", createdAt: created + 60, relyingPartyId: "rp.example")
            ],
            nextToken: "page-2"
        ))
        XCTAssertEqual(
            harness.keychain.writtenAccounts.filter { $0 == harness.store().sessionAccount(for: work) },
            [],
            "work's record was written"
        )
    }

    /// - Given: a signed-in session
    /// - When: it lists with the default options
    /// - Then:
    ///    - the engine is asked for the first page (no token) of 20, the plugin's default
    func testListDefaultsToTheFirstPageOfTwenty() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))

        let result = try await client.listWebAuthnCredentials()

        XCTAssertEqual(AuthClientListWebAuthnCredentialsOptions(), .init(pageSize: 20, nextToken: nil))
        XCTAssertEqual(engine.phase5Calls.map(\.operation), [.listWebAuthnCredentials])
        guard case .listWebAuthnCredentials(_, let pageSize, let nextToken) = engine.phase5Calls.first else {
            return XCTFail("\(engine.phase5Calls)")
        }
        XCTAssertEqual(pageSize, 20)
        XCTAssertNil(nextToken)
        XCTAssertEqual(result, AuthClientListWebAuthnCredentialsResult(credentials: [], nextToken: nil))
    }

    /// Pagination: the result's next token, passed back in the options, asks for the next page.
    ///
    /// - Given: an engine with three credentials, answering pages of two
    /// - When: the caller lists, then lists again with the first result's next token
    /// - Then:
    ///    - the second call carries that token, and the two pages hold all three credentials, the last with
    ///      no next token
    func testTheNextTokenAsksForTheNextPage() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let all = (1 ... 3).map {
            EngineWebAuthnCredential(credentialId: "cred-\($0)", createdAt: created, relyingPartyId: "rp.example", friendlyName: nil)
        }
        engine.scriptPhase5(.listWebAuthnCredentials) { call in
            guard case .listWebAuthnCredentials(_, let pageSize, let nextToken) = call else {
                throw FixtureError(description: "\(call)")
            }
            let start = nextToken.flatMap(Int.init) ?? 0
            let end = min(start + pageSize, all.count)
            return EngineWebAuthnCredentialPage(credentials: Array(all[start ..< end]), nextToken: end < all.count ? "\(end)" : nil)
        }

        let first = try await client.listWebAuthnCredentials(options: .init(pageSize: 2))
        let second = try await client.listWebAuthnCredentials(options: .init(pageSize: 2, nextToken: first.nextToken))

        XCTAssertEqual(first.credentials.map(\.credentialId), ["cred-1", "cred-2"])
        XCTAssertEqual(first.nextToken, "2")
        XCTAssertEqual(second.credentials.map(\.credentialId), ["cred-3"])
        XCTAssertNil(second.nextToken)
        XCTAssertEqual(engine.phase5Calls.map(\.payload), [FakePayload.signedIn("alice").data, FakePayload.signedIn("alice").data])
    }

    // MARK: Page size

    /// The client checks the page size itself, where the plugin leaves it to Cognito.
    ///
    /// - Given: a signed-in session, and a signed-out one
    /// - When: each lists with page sizes 0, 21 and `UInt.max`
    /// - Then:
    ///    - each throws `validation(field: "pageSize")`, the signed-out session too (the check comes first),
    ///      and no engine is called
    func testAPageSizeOutsideOneToTwentyIsRefusedBeforeAnything() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let signedIn = try harness.client(work)
        let signedOut = try harness.client(home)

        for client in [signedIn, signedOut] {
            for pageSize: UInt in [0, 21, .max] {
                await assertThrowsAsync({ try await client.listWebAuthnCredentials(options: .init(pageSize: pageSize)) }) { error in
                    guard case .validation(let field, let description, _, _) = authError(error) else {
                        return XCTFail("\(pageSize): \(error)")
                    }
                    XCTAssertEqual(field, "pageSize")
                    XCTAssertEqual(description, "pageSize must be from 1 to 20 to listWebAuthnCredentials")
                }
            }
        }
        XCTAssertEqual(harness.engine(for: work)?.phase5Calls, [])
        XCTAssertEqual(harness.engine(for: home)?.phase5Calls, [])
    }

    /// - Given: a signed-in session
    /// - When: it lists with page sizes 1 and 20, the range's ends
    /// - Then:
    ///    - both reach the engine unchanged
    func testThePageSizeRangesEndsAreAccepted() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))

        _ = try await client.listWebAuthnCredentials(options: .init(pageSize: 1))
        _ = try await client.listWebAuthnCredentials(options: .init(pageSize: 20))

        let sizes = engine.phase5Calls.compactMap { call -> Int? in
            guard case .listWebAuthnCredentials(_, let pageSize, _) = call else {
                return nil
            }
            return pageSize
        }
        XCTAssertEqual(sizes, [1, 20])
    }

    // MARK: Refusals

    /// - Given: a signed-out session, a guest session and a federated session
    /// - When: each lists and deletes
    /// - Then:
    ///    - each call throws `notSignedIn`, and no engine receives a call or refreshes
    func testSignedOutGuestAndFederatedSessionsAreRefused() async throws {
        let federated = ClientFixtures.id("federated")
        try harness.signIn(home, .guest(identityId: "us-east-1:guest"))
        try harness.signIn(federated, .federated())
        let clients = try [harness.client(work), harness.client(home), harness.client(federated)]

        for client in clients {
            await assertThrowsAsync({ try await client.listWebAuthnCredentials() }) { error in
                guard case .notSignedIn = authError(error) else {
                    return XCTFail("\(error)")
                }
            }
            await assertThrowsAsync({ try await client.deleteWebAuthnCredential(credentialId: "cred-1") }) { error in
                guard case .notSignedIn = authError(error) else {
                    return XCTFail("\(error)")
                }
            }
        }
        for id in [work, home, federated] {
            XCTAssertEqual(harness.engine(for: id)?.phase5Calls, [], "\(id)")
            XCTAssertEqual(harness.engine(for: id)?.refreshCalls, [], "\(id)")
        }
    }

    /// Neither call takes `signInLock` nor touches a pending challenge.
    ///
    /// - Given: a session waiting on a TOTP challenge
    /// - When: it lists and deletes, then answers the challenge
    /// - Then:
    ///    - both calls throw `notSignedIn` without reaching the engine, the challenge is still pending, and
    ///      answering it signs the user in
    func testAPendingChallengeIsRefusedAndLeftAlone() async throws {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        engine.scriptSignIn { _, _ in .challenge(.confirmSignInWithTOTPCode) }
        _ = try await client.signIn(username: "alice", password: "password")

        await assertThrowsAsync({ try await client.listWebAuthnCredentials() }) { error in
            XCTAssertEqual(authError(error)?.kind, .notSignedIn, "\(error)")
        }
        await assertThrowsAsync({ try await client.deleteWebAuthnCredential(credentialId: "cred-1") }) { error in
            XCTAssertEqual(authError(error)?.kind, .notSignedIn, "\(error)")
        }
        XCTAssertEqual(engine.phase5Calls, [])
        let pending = await client.currentSessionState()
        XCTAssertEqual(pending, .awaitingChallenge(.confirmSignInWithTOTPCode))

        let result = try await client.confirmSignIn(challengeResponse: "123456")
        XCTAssertEqual(result.nextStep, .done)
    }

    /// - Given: a signed-in session whose tokens need a refresh
    /// - When: a list and a delete run concurrently
    /// - Then:
    ///    - the session refreshes once, and both calls get the refreshed payload
    func testAStalePayloadIsRefreshedOnceForBoth() async throws {
        let stale = FakePayload.signedIn("alice", stale: true)
        try harness.signIn(work, stale)
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        let latch = Gate()
        engine.holdRefreshes(on: latch)

        async let list = client.listWebAuthnCredentials()
        async let delete: Void = client.deleteWebAuthnCredential(credentialId: "cred-1")
        await latch.waitForArrivals(1)
        await waitUntil("both calls wait on the one refresh") { await client.core.refreshFlight.waiterCount == 2 }
        await latch.open()
        _ = try await (list, delete)

        XCTAssertEqual(engine.refreshCalls, [stale.data])
        XCTAssertEqual(engine.phase5Calls.map(\.payload), [stale.refreshed.data, stale.refreshed.data])
    }

    // MARK: Errors

    /// - Given: a signed-in session whose engine fails
    /// - When: list and delete are called
    /// - Then:
    ///    - an `AuthClientError` (a service error) and a `CancellationError` pass through as they are
    ///    - anything else is `unknown`, naming the operation
    func testEngineFailuresAreMapped() async throws {
        try harness.signIn(work, .signedIn("alice"))
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))

        engine.scriptPhase5(.listWebAuthnCredentials) { _ in
            throw AuthClientError.service(.webAuthnNotEnabled, "not enabled", "enable it")
        }
        await assertThrowsAsync({ try await client.listWebAuthnCredentials() }) { error in
            guard case .service(.webAuthnNotEnabled?, _, _, _) = authError(error) else {
                return XCTFail("\(error)")
            }
        }

        engine.scriptPhase5(.deleteWebAuthnCredential) { _ in throw CancellationError() }
        await assertThrowsAsync({ try await client.deleteWebAuthnCredential(credentialId: "cred-1") }) { error in
            XCTAssertTrue(error is CancellationError, "\(error)")
        }

        engine.scriptPhase5(.deleteWebAuthnCredential) { _ in throw FixtureError(description: "boom") }
        await assertThrowsAsync({ try await client.deleteWebAuthnCredential(credentialId: "cred-1") }) { error in
            guard case .unknown(let description, _, let underlying) = authError(error) else {
                return XCTFail("\(error)")
            }
            XCTAssertEqual(description, "The client could not delete the WebAuthn credential.")
            XCTAssertTrue(underlying is FixtureError)
        }
    }

    // MARK: Model parity

    /// Amplify's `AuthWebAuthnCredential` requirements, from `Amplify/Categories/Auth/Models/AuthWebAuthnCredential.swift`
    /// lines 44-53 (the plugin's `AWSCognitoWebAuthnCredential` has the same stored properties).
    static let amplifyCredentialFields = ["credentialId", "createdAt", "relyingPartyId", "friendlyName"]
    /// `AuthListWebAuthnCredentialsResult`, the same file, lines 18 and 26.
    static let amplifyListResultFields = ["credentials", "nextToken"]
    /// `AuthListWebAuthnCredentialsRequest.Options`, `Amplify/Categories/Auth/Request/AuthListWebAuthnCredentialsRequest.swift`
    /// lines 34, 42 and 49, less `pluginOptions`: the client has no plugin options.
    static let amplifyListOptionsFields = ["pageSize", "nextToken"]

    /// - Given: one value of each client WebAuthn model
    /// - When: its stored properties are read
    /// - Then:
    ///    - they are Amplify's, in Amplify's order, and the options default to Amplify's (page size 20, no
    ///      token); `AuthDeleteWebAuthnCredentialRequest.Options` has only `pluginOptions`, so the client
    ///      has no delete options
    func testTheModelsMirrorAmplifysFields() {
        let credential = AuthClientWebAuthnCredential(credentialId: "c", createdAt: created, relyingPartyId: "rp")
        let result = AuthClientListWebAuthnCredentialsResult(credentials: [credential])
        let options = AuthClientListWebAuthnCredentialsOptions()

        XCTAssertEqual(Mirror(reflecting: credential).children.compactMap(\.label), Self.amplifyCredentialFields)
        XCTAssertEqual(Mirror(reflecting: result).children.compactMap(\.label), Self.amplifyListResultFields)
        XCTAssertEqual(Mirror(reflecting: options).children.compactMap(\.label), Self.amplifyListOptionsFields)
        XCTAssertEqual(options.pageSize, 20)
        XCTAssertNil(options.nextToken)
        XCTAssertNil(credential.friendlyName)
        XCTAssertNil(result.nextToken)
    }
}
