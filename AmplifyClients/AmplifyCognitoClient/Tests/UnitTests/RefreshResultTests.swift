//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// What a refresh hands out: its own committed result as it is, as the plugin hands out what its refresh
/// established, and another writer's record, adopted or re-read, only if it needs no refresh.
final class RefreshResultTests: XCTestCase {

    private var harness: ClientHarness!
    private let work = ClientFixtures.id("work")

    override func setUp() {
        harness = ClientHarness()
    }

    override func tearDown() async throws {
        await harness.waitForBaseline()
        harness = nil
    }

    /// A refresh whose result still reads as needing one: what a device clock running ahead of Cognito's makes
    /// of every refresh Cognito accepts.
    private func refreshesStayStale(_ engine: FakeSessionEngine) {
        engine.scriptRefresh { payload in
            var next = try XCTUnwrap(FakePayload.decode(payload))
            next.version += 1
            return next.data
        }
    }

    /// The plugin checks the credentials once, before it refreshes, and hands out what the refresh established
    /// (`FetchAuthSessionOperationHelper.listenForSession`), with no skew estimate and no second check.
    ///
    /// - Given: a signed-in session needing a refresh, on a device whose clock runs so far ahead that every
    ///   refreshed payload still reads as needing a refresh
    /// - When: both providers are asked, and the session is fetched
    /// - Then:
    ///    - each call refreshes once, as the plugin does with the same clock, and hands out the credentials it
    ///      committed, never `unknown`
    func testARefreshThatStillReadsAsStaleHandsOutWhatItCommitted() async throws {
        let stale = FakePayload.signedIn("alice", version: 1, stale: true)
        try harness.signIn(work, stale)
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        refreshesStayStale(engine)

        let credentials = try await client.credentialsProvider.resolve()
        let token = try await client.userPoolTokenProvider.accessToken()
        let session = try await client.fetchAuthSession()

        XCTAssertEqual(credentials as? CognitoAWSCredentials, FakePayload.signedIn("alice", version: 2).awsCredentials)
        XCTAssertEqual(token, "access-alice-v3")
        XCTAssertEqual(try session.awsCredentialsResult.get(), AuthClientAWSCredentials(FakePayload.signedIn("alice", version: 4).awsCredentials))
        XCTAssertEqual(try session.userPoolTokensResult.get().accessToken, "access-alice-v4")
        XCTAssertEqual(engine.refreshCalls.count, 3)
        XCTAssertEqual(try harness.storedRecord(work)?.credentials, FakePayload.signedIn("alice", version: 4, stale: true).data)
    }

    /// Another writer's record is not this refresh's result: one that still needs a refresh is never handed out.
    ///
    /// - Given: a session needing a refresh, and another process that stores credentials still needing one while
    ///   the engine is refreshing, every time, so each refresh's commit loses and adopts them
    /// - When: credentials are requested, and the session is fetched
    /// - Then:
    ///    - the provider throws `unknown`, and the session's fields fail with `unknown`
    func testAnAdoptedRecordThatStillNeedsARefreshIsNotHandedOut() async throws {
        let stale = FakePayload.signedIn("alice", version: 1, stale: true)
        try harness.signIn(work, stale)
        let client = try harness.client(work)
        let store = harness.store()
        let work = work
        // Every refresh loses to the other process, which stores credentials a hundred versions on, still stale.
        harness.engine(for: work)?.scriptRefresh { payload in
            let sent = try XCTUnwrap(FakePayload.decode(payload))
            if case .record(let envelope) = try store.read(work) {
                try store.write(FakePayload.signedIn("alice", version: sent.version + 100, stale: true).record(), for: work, expecting: envelope.version)
            }
            return sent.refreshed.data
        }

        let error: CredentialsError?
        do {
            _ = try await client.credentialsProvider.resolve()
            error = nil
            XCTFail("expected an error")
        } catch let thrown as CredentialsError {
            error = thrown
        }
        let session = try await client.fetchAuthSession()

        XCTAssertEqual(error?.isUnknown, true, "\(String(describing: error))")
        XCTAssertThrowsError(try session.awsCredentialsResult.get()) { error in
            XCTAssertEqual((error as? AuthClientError)?.kind, .unknown)
        }
        XCTAssertEqual(try harness.storedRecord(work)?.credentials, FakePayload.signedIn("alice", version: 201, stale: true).data)
    }
}
