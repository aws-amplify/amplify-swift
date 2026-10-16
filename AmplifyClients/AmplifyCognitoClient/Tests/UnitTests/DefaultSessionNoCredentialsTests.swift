//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// `.default` over the Auth plugin's signed-out record, `{"noCredentials":{}}`, with no sidecar: what a plugin or a
/// client sign-out leaves. It is a present record that holds no session: nothing to revoke, nothing to report as
/// signed out when it is ended again, and labelling it never turns it into credentials.
final class DefaultSessionNoCredentialsTests: XCTestCase {

    /// Exactly what the plugin writes.
    private let noCredentials = Data(#"{"noCredentials":{}}"#.utf8)

    private var harness: ClientHarness!
    private var pluginAccount: String { SessionRecordKey.pluginSessionAccount(in: StorageFixtures.pools) }

    override func setUp() {
        harness = ClientHarness()
        harness.keychain.put(noCredentials, pluginAccount)
    }

    override func tearDown() async throws {
        await harness.waitForBaseline()
        harness = nil
    }

    /// - Given: the plugin's signed-out record, and no sidecar
    /// - When: a fresh `.default` client reads its state, and its providers are asked
    /// - Then:
    ///    - it is `.signedOut`, without asking the engine to describe the record, and both providers throw
    ///      `notSignedIn`
    func testFreshRestoreOfNoCredentialsIsSignedOut() async throws {
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

    /// - Given: the plugin's signed-out record, with no live client
    /// - When: `.default` is signed out through the static call
    /// - Then:
    ///    - nothing is revoked, the result is `.complete`, and the record is left as it was
    func testStaticSignOutOfNoCredentialsRevokesNothing() async throws {
        let result = await AmplifyCognitoClient.signOutStoredSession(
            sessionId: .default,
            configuration: ClientFixtures.configuration,
            accessGroup: nil,
            dependencies: harness.dependencies
        )

        XCTAssertEqual(result, .complete)
        XCTAssertEqual(harness.revoker.revokeCalls, [])
        XCTAssertEqual(harness.keychain.value(pluginAccount), noCredentials)
    }

    /// - Given: a live `.default` client over the plugin's signed-out record, and an event subscriber
    /// - When: it is signed out, then purged, through the static calls
    /// - Then:
    ///    - its engine revoked nothing, no event was sent for either, and it is `.signedOut`
    func testLiveSignOutAndPurgeOfNoCredentialsSendNoEvent() async throws {
        let client = try harness.client(.default)
        _ = await client.currentSessionState()
        let events = StreamRecorder(client.listenToAuthEvents())

        let result = await AmplifyCognitoClient.signOutStoredSession(
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

    /// - Given: the plugin's signed-out record
    /// - When: `.default` is labelled
    /// - Then:
    ///    - only the sidecar is written: the record is still `{"noCredentials":{}}`, read as a labelled signed-out row
    func testLabelOverNoCredentialsKeepsTheRecordSignedOut() async throws {
        let client = try harness.client(.default)

        try await client.setSessionLabel("Main")

        XCTAssertEqual(harness.keychain.value(pluginAccount), noCredentials)
        XCTAssertEqual(try harness.storedRecord(.default), .signedOut(label: "Main", username: nil))
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
    }
}
