//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import AuthenticationServices
import XCTest
@testable import AWSCognitoAuthPlugin
@testable import InternalAWSCognitoAuth

/// `AssertWebAuthnCredentials` and the auth environment's `WebAuthnSignInCeremonySlot`: the plugin's path,
/// an empty slot, is unchanged; a filled slot (the client's) refuses a step with no window, and runs the
/// assertion through its runner.
///
/// - Note: `@unchecked Sendable` so the test body can be captured by the mocks' `@Sendable` closures.
@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
final class WebAuthnSignInCeremonySlotTests: XCTestCase, @unchecked Sendable {

    private let challenge = RespondToAuthChallenge(
        challenge: .webAuthn,
        availableChallenges: [],
        username: "alice",
        session: "session",
        parameters: [:]
    )

    /// The plugin's path: an empty slot asserts with the action's own asserter, and no runner exists to call.
    ///
    /// - Given: an auth environment whose slot is empty, and an action built with a recording asserter
    /// - When: the action runs
    /// - Then:
    ///    - the factory's asserter asserted once, and the event carries its payload to verify
    func testAnEmptySlotAssertsWithTheActionsOwnAsserter() async throws {
        let asserter = RecordingAsserter()
        let environment = Defaults.makeDefaultAuthEnvironment()
        XCTAssertNil(environment.webAuthnSignInCeremony.ceremony)
        let action = try makeAction(asserter: asserter)

        let events = await run(action, environment)

        XCTAssertEqual(asserter.asserts.get(), 1)
        guard case .verifyCredentialsAndSignIn(let payload, _)? = events.first?.eventType else {
            return XCTFail("expected verifyCredentialsAndSignIn, got \(events)")
        }
        XCTAssertEqual(try Self.json(payload), try Self.json(Self.payload().stringify()))
    }

    /// A filled slot with no window refuses before its runner, and presents nothing.
    ///
    /// - Given: an environment whose slot holds a ceremony with no anchor and a counting runner
    /// - When: the action runs
    /// - Then:
    ///    - the event is `.error` whose engine error is `.validation("presentationAnchor", …)`; the runner never
    ///      ran, and neither the action's asserter nor the slot's asserter factory was used
    func testAFilledSlotWithNoWindowRefusesWithoutAnAsserter() async throws {
        let asserter = RecordingAsserter()
        let runs = TestBox(0)
        let made = TestBox(0)
        let environment = Defaults.makeDefaultAuthEnvironment()
        environment.webAuthnSignInCeremony.ceremony = .init(
            anchor: nil,
            run: { body in
                runs.with { $0 += 1 }
                return try await body()
            },
            makeAsserter: { _ in
                made.with { $0 += 1 }
                return RecordingAsserter()
            }
        )

        let events = await run(try makeAction(asserter: asserter), environment)

        guard case .error(let error, _)? = events.first?.eventType else {
            return XCTFail("expected .error, got \(events)")
        }
        guard case .validation(let field, _, _, _) = error.engineError else {
            return XCTFail("expected .validation, got \(error.engineError)")
        }
        XCTAssertEqual(field, WebAuthnCredentialOperations.presentationAnchorField)
        XCTAssertEqual(runs.get(), 0)
        XCTAssertEqual(made.get(), 0)
        XCTAssertEqual(asserter.asserts.get(), 0)
    }

    /// A filled slot runs the assertion through its runner, with the asserter it makes from the window; a runner
    /// error reaches the event as `.unknown` with the original underneath.
    ///
    /// - Given: an environment whose slot holds a window's box and a runner that runs its body, then one that
    ///   throws its own error
    /// - When: the action runs with each
    /// - Then:
    ///    - the first: the runner ran once, the slot's asserter asserted on the main thread over the window, the
    ///      action's own asserter was not used, and the event carries the payload
    ///    - the second: the event is `.error(.unknown(…))` whose underlying error is the runner's
    func testAFilledSlotRunsTheAssertionThroughItsRunner() async throws {
        let window = await MainActor.run { ASPresentationAnchor() }
        let box = await MainActor.run { EnginePresentationAnchorBox(window) }
        let own = RecordingAsserter()
        let slotAsserter = RecordingAsserter()
        let madeOnMain = TestBox<[Bool]>([])
        let runs = TestBox(0)
        let environment = Defaults.makeDefaultAuthEnvironment()
        environment.webAuthnSignInCeremony.ceremony = .init(
            anchor: box,
            run: { body in
                runs.with { $0 += 1 }
                return try await body()
            },
            makeAsserter: { anchor in
                madeOnMain.with { $0.append(Thread.isMainThread && anchor === window) }
                return slotAsserter
            }
        )

        let first = await run(try makeAction(asserter: own), environment)

        guard case .verifyCredentialsAndSignIn(let payload, _)? = first.first?.eventType else {
            return XCTFail("expected verifyCredentialsAndSignIn, got \(first)")
        }
        XCTAssertEqual(try Self.json(payload), try Self.json(Self.payload().stringify()))
        XCTAssertEqual(runs.get(), 1)
        XCTAssertEqual(madeOnMain.get(), [true])
        XCTAssertEqual(slotAsserter.asserts.get(), 1)
        XCTAssertEqual(own.asserts.get(), 0)

        let refusal = RunnerRefusal()
        environment.webAuthnSignInCeremony.ceremony = .init(anchor: box, run: { _ in throw refusal })
        let second = await run(try makeAction(asserter: own), environment)

        guard case .error(.unknown(_, let underlying), _)? = second.first?.eventType else {
            return XCTFail("expected .error(.unknown), got \(second)")
        }
        XCTAssertTrue(underlying is RunnerRefusal)
        _ = window
    }

    // MARK: Support

    private func makeAction(asserter: RecordingAsserter) throws -> AssertWebAuthnCredentials {
        let options = try CredentialAssertionOptions(from: #"{"challenge":"Y2hhbGxlbmdl","rpId":"example.com"}"#)
        return AssertWebAuthnCredentials(
            username: "alice",
            options: options,
            respondToAuthChallenge: challenge,
            presentationAnchor: nil,
            logger: AmplifyEngineLogRouter(),
            asserterFactory: { _ in asserter }
        )
    }

    private func run(_ action: AssertWebAuthnCredentials, _ environment: AuthEnvironment) async -> [WebAuthnEvent] {
        let events = TestBox<[WebAuthnEvent]>([])
        await action.execute(
            withDispatcher: MockDispatcher { event in
                if let event = event as? WebAuthnEvent {
                    events.with { $0.append(event) }
                }
            },
            environment: environment
        )
        return events.get()
    }

    /// A JSON document, for comparing two encodings whose key order may differ.
    private static func json(_ text: String) throws -> NSDictionary {
        try XCTUnwrap(JSONSerialization.jsonObject(with: Data(text.utf8)) as? NSDictionary)
    }

    static func payload() throws -> CredentialAssertionPayload {
        let json = #"""
        {"id":"Y3JlZA","rawId":"Y3JlZA","type":"public-key","authenticatorAttachment":"platform",
         "response":{"authenticatorData":"YXV0aA","clientDataJSON":"Y2xpZW50","signature":"c2ln","userHandle":"dXNlcg"}}
        """#
        return try JSONDecoder().decode(CredentialAssertionPayload.self, from: Data(json.utf8))
    }
}

@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
private final class RecordingAsserter: CredentialAsserterProtocol, @unchecked Sendable {
    let asserts = TestBox(0)
    var presentationAnchor: EnginePresentationAnchor? { nil }

    func assert(with options: CredentialAssertionOptions) async throws -> CredentialAssertionPayload {
        asserts.with { $0 += 1 }
        return try WebAuthnSignInCeremonySlotTests.payload()
    }
}

private struct RunnerRefusal: Error {}
#endif
