//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) import AmplifyFoundation
import Security
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient

/// A sign-out that ended the session, whose read of the record afterwards fails.
final class SignOutRereadFailureTests: XCTestCase {

    private var harness: ClientHarness!
    private let work = ClientFixtures.id("work")

    override func setUp() {
        harness = ClientHarness()
    }

    override func tearDown() async throws {
        harness.keychain.clearFailures()
        await harness.waitForBaseline()
        harness = nil
    }

    /// A sign-out that ends the session cancels its pending sign-in whether or not it removed credentials, and
    /// whether or not the record could be read back.
    ///
    /// - Given: a signed-out session whose sign-in waits on a challenge, and a record that cannot be read once the
    ///   sign-out has read it
    /// - When: the session is signed out
    /// - Then:
    ///    - the sign-out completes, the state is `.signedOut`, not `.awaitingChallenge`, and no event is sent
    func testASignOutWhoseReReadFailsStillClearsThePendingChallenge() async throws {
        let client = try harness.client(work)
        let engine = try XCTUnwrap(harness.engine(for: work))
        engine.scriptSignIn { _, _ in .challenge(.confirmSignInWithTOTPCode) }
        let started = try await client.signInForTest("alice")
        XCTAssertEqual(started.nextStep, .confirmSignInWithTOTPCode)
        let events = StreamRecorder(client.listenToAuthEvents())
        let account = harness.store().sessionAccount(for: work)
        let keychain = harness.keychain
        keychain.onceAfterReading(account) {
            keychain.failingReads(of: account, with: errSecInteractionNotAllowed)
        }

        let result = await client.signOut()
        keychain.clearFailures()

        XCTAssertEqual(result, .complete)
        let state = await client.currentSessionState()
        XCTAssertEqual(state, .signedOut)
        XCTAssertEqual(events.received, [])
    }
}
