//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// `InitiateSignOut`'s first step, and `SignOutEventData.skipHostedUISignOut`: the plugin
/// never sets it, so a hosted-UI session still signs out through the hosted UI; a caller that sets it goes
/// straight to the revoke or the global sign-out.
final class InitiateSignOutTests: XCTestCase {

    /// A hosted-UI session signs out through the hosted UI by default.
    ///
    /// - Given: signed-in data from a hosted-UI sign-in that is not a private session
    /// - When:
    ///    - `InitiateSignOut` runs with the plugin's event data (`skipHostedUISignOut` defaulted)
    /// - Then:
    ///    - it sends `invokeHostedUISignOut`
    ///
    func testAHostedUISessionSignsOutThroughTheHostedUIByDefault() async throws {
        let event = try await firstEvent(signOut: SignOutEventData(globalSignOut: false))

        guard case .invokeHostedUISignOut = event else {
            return XCTFail("expected invokeHostedUISignOut, got \(event)")
        }
    }

    /// Skipping the hosted UI goes straight to the revoke.
    ///
    /// - Given: the same hosted-UI signed-in data
    /// - When:
    ///    - `InitiateSignOut` runs with `skipHostedUISignOut: true`
    /// - Then:
    ///    - it sends `revokeToken`
    ///
    func testSkippingTheHostedUIRevokes() async throws {
        let event = try await firstEvent(signOut: SignOutEventData(globalSignOut: false, skipHostedUISignOut: true))

        guard case .revokeToken = event else {
            return XCTFail("expected revokeToken, got \(event)")
        }
    }

    /// Skipping the hosted UI with a global sign-out goes straight to the global sign-out.
    ///
    /// - Given: the same hosted-UI signed-in data
    /// - When:
    ///    - `InitiateSignOut` runs with `globalSignOut: true, skipHostedUISignOut: true`
    /// - Then:
    ///    - it sends `signOutGlobally`
    ///
    func testSkippingTheHostedUISignsOutGlobally() async throws {
        let event = try await firstEvent(signOut: SignOutEventData(globalSignOut: true, skipHostedUISignOut: true))

        guard case .signOutGlobally = event else {
            return XCTFail("expected signOutGlobally, got \(event)")
        }
    }

    /// The flag is never encoded: a decoded event data does not skip.
    ///
    /// - Given: event data with `skipHostedUISignOut: true`
    /// - When:
    ///    - it is encoded and decoded
    /// - Then:
    ///    - the decoded value has `skipHostedUISignOut == false`, and the same `globalSignOut`
    ///
    func testTheSkipIsNotEncoded() throws {
        let data = try JSONEncoder().encode(SignOutEventData(globalSignOut: true, skipHostedUISignOut: true))

        let decoded = try JSONDecoder().decode(SignOutEventData.self, from: data)

        XCTAssertTrue(decoded.globalSignOut)
        XCTAssertFalse(decoded.skipHostedUISignOut)
    }

    private func firstEvent(signOut: SignOutEventData) async throws -> SignOutEvent.EventType {
        let signedInData = SignedInData(
            signedInDate: Date(),
            signInMethod: .hostedUI(HostedUIOptions(
                scopes: ["openid"],
                providerInfo: HostedUIProviderInfo(authProvider: nil, idpIdentifier: nil),
                presentationAnchor: nil,
                preferPrivateSession: false,
                nonce: nil,
                language: nil,
                loginHint: nil,
                prompt: nil,
                resource: nil
            )),
            cognitoUserPoolTokens: .testData
        )
        let action = InitiateSignOut(signedInData: signedInData, signOutEventData: signOut)
        let events = TestBox<[SignOutEvent.EventType]>([])
        let dispatcher = MockDispatcher { event in
            if let event = event as? SignOutEvent {
                events.with { $0.append(event.eventType) }
            }
        }

        await action.execute(withDispatcher: dispatcher, environment: MockInvalidEnvironment())

        return try XCTUnwrap(events.get().first)
    }
}
