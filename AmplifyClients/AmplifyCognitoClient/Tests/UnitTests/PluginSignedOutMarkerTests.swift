//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// The Auth plugin's signed-out marker, `{"noCredentials":{}}`, under the plugin's key.
///
/// The forward-compatible plugin writes it on sign-out while a client record exists, instead of
/// deleting its record. It is a present record that holds no session, so `.default` reading through to it
/// is signed out: nothing to revoke, nothing to report as signed out when it is purged, nothing to adopt.
final class PluginSignedOutMarkerTests: XCTestCase {

    /// Exactly what the plugin writes.
    private let marker = Data(#"{"noCredentials":{}}"#.utf8)

    private var harness: ClientHarness!
    private var pluginAccount: String { SessionRecordKey.legacySessionAccount(in: StorageFixtures.pools) }

    override func setUp() {
        harness = ClientHarness()
        harness.keychain.put(marker, pluginAccount)
    }

    override func tearDown() async throws {
        await harness.waitForBaseline()
        harness = nil
    }

    /// - Given: `.default` with no record of its own, and the plugin's signed-out marker
    /// - When: its state is read, and its providers are asked
    /// - Then:
    ///    - it is `.signedOut`, without asking the engine to read the marker, and both providers throw
    ///      `notSignedIn`
    func testReadThroughOfTheMarkerIsSignedOut() async throws {
        let client = try harness.client(.default)

        let state = await client.currentSessionState()

        XCTAssertEqual(state, .signedOut)
        XCTAssertEqual(harness.engine(for: .default)?.describeCount, 0)
        await assertThrowsAsync({ try await client.credentialsProvider.resolve() }) { error in
            XCTAssertEqual((error as? CredentialsError)?.isNotSignedIn, true, "\(error)")
        }
        await assertThrowsAsync({ try await client.userPoolTokenProvider.accessToken() }) { error in
            XCTAssertEqual((error as? CredentialsError)?.isNotSignedIn, true, "\(error)")
        }
    }

    /// - Given: `.default` reading through to the marker, with no live client
    /// - When: it is signed out through the static call
    /// - Then:
    ///    - nothing is revoked, and the result is `.complete`
    func testStaticSignOutDoesNotRevokeTheMarker() async throws {
        let result = try await AmplifyCognitoClient.signOutStoredSession(
            sessionId: .default,
            configuration: ClientFixtures.configuration,
            accessGroup: nil,
            dependencies: harness.dependencies
        )

        XCTAssertEqual(result, .complete)
        XCTAssertEqual(harness.revoker.revokeCalls, [])
    }

    /// - Given: a live `.default` client reading through to the marker, and an event subscriber
    /// - When: it is signed out, and then purged, through the static calls
    /// - Then:
    ///    - its engine revoked nothing, no `.signedOut` event was sent for either, and it is `.signedOut`
    func testLiveSignOutAndPurgeOfTheMarkerSendNoEvent() async throws {
        let client = try harness.client(.default)
        _ = await client.currentSessionState()
        let events = StreamRecorder(client.listenToAuthEvents())

        let result = try await AmplifyCognitoClient.signOutStoredSession(
            sessionId: .default,
            configuration: ClientFixtures.configuration,
            accessGroup: nil,
            dependencies: harness.dependencies
        )
        try await AmplifyCognitoClient.purgeStoredSession(
            sessionId: .default,
            configuration: ClientFixtures.configuration,
            accessGroup: nil,
            dependencies: harness.dependencies
        )

        XCTAssertEqual(result, .complete)
        XCTAssertEqual(harness.engine(for: .default)?.revokeCalls, [])
        XCTAssertEqual(events.received, [])
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }

    /// - Given: `.default` reading through to the marker
    /// - When: a label is set, and adoption completes
    /// - Then:
    ///    - the label creates a signed-out row of `.default`'s own, and adoption, with nothing to adopt,
    ///      succeeds; the marker is not copied into the own record as credentials
    func testLabelAndAdoptionTreatTheMarkerAsNoSession() async throws {
        let client = try harness.client(.default)

        try await client.setSessionLabel("Main")
        try await client.completeAdoption()

        XCTAssertEqual(try harness.storedRecord(.default), .signedOut(label: "Main", username: nil))
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }
}
