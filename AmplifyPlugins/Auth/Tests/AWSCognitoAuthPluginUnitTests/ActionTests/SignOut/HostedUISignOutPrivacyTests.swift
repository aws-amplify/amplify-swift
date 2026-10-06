//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// The hosted-UI sign-out, engine side: it opens the browser with
/// the sign-in's own privacy choice, and `SignedInData.signOutPresentsBrowser` says when it opens one at all.
///
/// - Note: `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
///   `@Sendable` closures the API takes. XCTest runs one test at a time.
class HostedUISignOutPrivacyTests: XCTestCase, @unchecked Sendable {

    /// Test that the logout browser uses the sign-in's cookie jar
    ///
    /// - Given: Hosted-UI sign-ins that shared the browser's cookies and that preferred a private session, and
    ///   an API sign-in
    /// - When:
    ///    - `ShowHostedUISignOut` runs for each
    /// - Then:
    ///    - The browser is opened private exactly when the sign-in was private, and not private for an API
    ///      sign-in
    ///
    func testLogoutBrowserUsesTheSignInsPrivacy() async {
        for (signInData, expected) in [
            (Self.hostedUI(preferPrivateSession: false), false),
            (Self.hostedUI(preferPrivateSession: true), true),
            (SignedInData.testData, false)
        ] {
            let session = RecordingHostedUISession()
            let action = ShowHostedUISignOut(
                signOutEvent: SignOutEventData(globalSignOut: false),
                signInData: signInData
            )
            await action.execute(
                withDispatcher: MockDispatcher { _ in },
                environment: Defaults.makeDefaultAuthEnvironment(hostedUIEnvironment: Self.hostedUIEnvironment(session))
            )
            XCTAssertEqual(session.inPrivateValues, [expected], "\(signInData.signInMethod)")
        }
    }

    /// Test the sign-in's privacy as the engine reads it
    ///
    /// - Given: Hosted-UI sign-ins with each privacy choice, and an API sign-in
    /// - When:
    ///    - `hostedUIPrefersPrivateSession` is read
    /// - Then:
    ///    - It is the sign-in's choice, and `nil` for an API sign-in
    ///
    func testHostedUIPrefersPrivateSessionReadsTheSignIn() {
        XCTAssertEqual(Self.hostedUI(preferPrivateSession: true).hostedUIPrefersPrivateSession, true)
        XCTAssertEqual(Self.hostedUI(preferPrivateSession: false).hostedUIPrefersPrivateSession, false)
        XCTAssertNil(SignedInData.testData.hostedUIPrefersPrivateSession)
    }

    /// Test that `signOutPresentsBrowser` agrees with `InitiateSignOut`
    ///
    /// - Given: An API sign-in, a hosted-UI sign-in that shared the browser's cookies, and a private hosted-UI
    ///   sign-in, each signed out locally and globally
    /// - When:
    ///    - `InitiateSignOut` runs for each
    /// - Then:
    ///    - It sends `invokeHostedUISignOut` exactly when `signOutPresentsBrowser` is true, which is only for
    ///      the shared-cookie hosted-UI sign-in
    ///
    func testSignOutPresentsBrowserAgreesWithInitiateSignOut() async {
        let cases: [(SignedInData, Bool)] = [
            (SignedInData.testData, false),
            (Self.hostedUI(preferPrivateSession: false), true),
            (Self.hostedUI(preferPrivateSession: true), false)
        ]
        for (signInData, presents) in cases {
            XCTAssertEqual(signInData.signOutPresentsBrowser, presents, "\(signInData.signInMethod)")
            for global in [false, true] {
                let sentHostedUISignOut = await invokesHostedUISignOut(signInData, global: global)
                XCTAssertEqual(sentHostedUISignOut, presents, "\(signInData.signInMethod), global: \(global)")
            }
        }
    }

    // MARK: - Helpers

    private func invokesHostedUISignOut(_ signInData: SignedInData, global: Bool) async -> Bool {
        let events = EventRecorder()
        let action = InitiateSignOut(
            signedInData: signInData,
            signOutEventData: SignOutEventData(globalSignOut: global)
        )
        await action.execute(
            withDispatcher: MockDispatcher { events.append($0) },
            environment: Defaults.makeDefaultAuthEnvironment()
        )
        let sent = events.events.compactMap { ($0 as? SignOutEvent)?.eventType }
        XCTAssertEqual(sent.count, 1)
        guard case .invokeHostedUISignOut = sent.first else {
            return false
        }
        return true
    }

    private static func hostedUI(preferPrivateSession: Bool) -> SignedInData {
        SignedInData(
            signedInDate: Date(),
            signInMethod: .hostedUI(HostedUIOptions(
                scopes: [],
                providerInfo: HostedUIProviderInfo(authProvider: nil, idpIdentifier: nil),
                presentationAnchor: nil,
                preferPrivateSession: preferPrivateSession,
                nonce: nil,
                language: nil,
                loginHint: nil,
                prompt: nil,
                resource: nil
            )),
            cognitoUserPoolTokens: EngineUserPoolTokens.testData
        )
    }

    private static func hostedUIEnvironment(_ session: RecordingHostedUISession) -> HostedUIEnvironment {
        BasicHostedUIEnvironment(
            configuration: HostedUIConfigurationData(
                clientId: "clientId",
                oauth: OAuthConfigurationData(
                    domain: "cognitodomain",
                    scopes: ["openid"],
                    signInRedirectURI: "myapp://",
                    signOutRedirectURI: "myapp://"
                )
            ),
            hostedUISessionFactory: { session },
            urlSessionFactory: { URLSession.shared },
            randomStringFactory: { MockRandomStringGenerator(mockString: "mockString", mockUUID: "mockUUID") }
        )
    }
}

/// A hosted-UI session that records the privacy it was asked for, and succeeds.
final class RecordingHostedUISession: HostedUISessionBehavior, @unchecked Sendable {

    private let lock = NSLock()
    private var recorded: [Bool] = []

    var inPrivateValues: [Bool] {
        lock.withLock { recorded }
    }

    func showHostedUI(
        url: URL,
        callbackScheme: String,
        inPrivate: Bool,
        presentationAnchor: EnginePresentationAnchor?
    ) async throws -> [URLQueryItem] {
        lock.withLock { recorded.append(inPrivate) }
        return []
    }
}

/// Collects the events an action sends.
final class EventRecorder: @unchecked Sendable {

    private let lock = NSLock()
    private var recorded: [StateMachineEvent] = []

    var events: [StateMachineEvent] {
        lock.withLock { recorded }
    }

    func append(_ event: StateMachineEvent) {
        lock.withLock { recorded.append(event) }
    }
}
