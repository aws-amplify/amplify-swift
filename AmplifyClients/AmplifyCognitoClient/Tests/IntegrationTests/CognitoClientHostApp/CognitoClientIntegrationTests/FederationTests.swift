//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
import XCTest

/// Federation against the sandbox's identity pool (R-IP). The sandbox has no external
/// identity provider, so only the rejection is reachable, as in the plugin's `FederatedSessionTests`.
final class FederationTests: ClientIntegrationTestCase {

    /// FE-1, the plugin's `FederatedSessionTests.testUnsuccessfulFederation`: a token the identity pool cannot
    /// accept is rejected, and the session is left as it was.
    ///
    /// - Given: a signed-out session on the base sandbox configuration (R-UP + R-IP)
    /// - When:
    ///    - it federates a made-up Facebook token (R-IP has no Facebook provider)
    /// - Then:
    ///    - it throws `notAuthorized`, as the plugin's `AuthError.notAuthorized`
    ///    - the session is still signed out, and no record was stored for it
    ///
    func testUnsuccessfulFederation() async throws {
        let client = try makeClient("federate")

        do {
            _ = try await client.federateToIdentityPool(withProviderToken: "someToken", for: .facebook)
            XCTFail("federating an invalid token should fail")
        } catch let error as AuthClientError {
            guard case .notAuthorized = error else {
                return XCTFail("expected notAuthorized, got \(Self.caseName(of: error))")
            }
        }

        let state = await client.currentSessionState()
        XCTAssertTrue(state == .signedOut, "the session should still be signed out")
        let stored = try await AmplifyCognitoClient.storedSessions(
            configuration: IntegrationTestEnvironment.configuration(),
            includingSignedOut: true
        )
        XCTAssertFalse(stored.contains { $0.sessionId == client.sessionId }, "a rejected federation stores nothing")
    }

    /// The plugin keeps the previous credentials when a federation fails; so does the client.
    ///
    /// - Given: a guest session on R-IP
    /// - When:
    ///    - it federates a made-up Facebook token
    /// - Then:
    ///    - it throws `notAuthorized`, and the session is still the same guest, with the same identity
    ///
    func testUnsuccessfulFederationKeepsTheGuest() async throws {
        let client = try makeClient("fedguest")
        let before = try await client.fetchAuthSession().identityIdResult.get()
        let guestState = await client.currentSessionState()
        XCTAssertTrue(guestState == .guest, "the session should be a guest")

        do {
            _ = try await client.federateToIdentityPool(withProviderToken: "someToken", for: .facebook)
            XCTFail("federating an invalid token should fail")
        } catch let error as AuthClientError {
            guard case .notAuthorized = error else {
                return XCTFail("expected notAuthorized, got \(Self.caseName(of: error))")
            }
        }

        let state = await client.currentSessionState()
        XCTAssertTrue(state == .guest, "the session should still be a guest")
        let after = try await client.fetchAuthSession().identityIdResult.get()
        // Compared without printing: identity IDs stay out of the logs.
        XCTAssertTrue(after == before, "the guest identity changed")
    }

    /// The error's case name only: a service message can name the identity pool.
    private static func caseName(of error: AuthClientError) -> String {
        Mirror(reflecting: error).children.first?.label ?? "unknown"
    }
}
