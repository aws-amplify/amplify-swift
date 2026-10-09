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
import InternalAWSCognitoAuth

/// `associate`'s ceremony: the runner around it, the anchor box unboxed at ceremony start, and whose
/// errors are whose.
///
/// - Note: `@unchecked Sendable` so the test body can be captured by the mocks' `@Sendable` closures.
///   `XCTestCase` is not `Sendable`, and each test runs alone.
@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
final class WebAuthnAssociateCeremonyTests: XCTestCase, @unchecked Sendable {
    private var fixture: WebAuthnOperationsFixture!
    private var registrant: MockCredentialRegistrant!
    /// What happened, in order: `start`, `runner-in`, `registrant`, `create`, `runner-out`, `complete`.
    private let events = TestBox<[String]>([])
    /// The anchors the registrant factory was given, and whether it ran on the main thread.
    private let factoryCalls = TestBox<[(anchor: ObjectIdentifier?, onMainThread: Bool)]>([])

    override func setUp() {
        fixture = WebAuthnOperationsFixture()
        events.set([])
        factoryCalls.set([])
        registrant = MockCredentialRegistrant()
        registrant.mockedCreateResponse = .success(
            .init(credentialId: "credentialId", attestationObject: "attestationObject", clientDataJSON: "clientDataJSON")
        )
        let events = events
        fixture.identityProvider.mockStartWebAuthnRegistrationResponse = { _ in
            events.with { $0.append("start") }
            return WebAuthnAssociateOperationTests.startResponse()
        }
        fixture.identityProvider.mockCompleteWebAuthnRegistrationResponse = { _ in
            events.with { $0.append("complete") }
            return .init()
        }
    }

    override func tearDown() {
        registrant = nil
        fixture = nil
    }

    /// The ceremony runs once, inside the runner, between start and complete
    ///
    /// - Given: a runner that records entering and leaving, and a box holding a live window
    /// - When:
    ///    - `associate` runs
    /// - Then:
    ///    - start, then the runner, inside it the registrant made from that window on the main thread and
    ///      its ceremony, then complete
    ///
    func testAssociate_runsTheCeremonyOnceInsideTheRunner() async throws {
        let (window, box) = await Self.liveWindowBox()

        try await associate(anchor: box, ceremony: recordingRunner())

        XCTAssertEqual(events.get(), ["start", "runner-in", "registrant", "create", "runner-out", "complete"])
        let calls = factoryCalls.get()
        XCTAssertEqual(calls.count, 1)
        XCTAssertEqual(calls.first?.anchor, ObjectIdentifier(window))
        XCTAssertEqual(calls.first?.onMainThread, true)
        withExtendedLifetime(window) {}
    }

    /// No box: the registrant is made with no window
    ///
    /// - Given: `anchor: nil` (the plugin's call without an anchor)
    /// - When:
    ///    - `associate` runs
    /// - Then:
    ///    - the registrant factory gets `nil`, on the main thread, and the association completes
    ///
    func testAssociate_withNoBox_makesTheRegistrantWithNoWindow() async throws {
        try await associate(anchor: nil, ceremony: WebAuthnCredentialOperations.runCeremonyDirectly)

        let calls = factoryCalls.get()
        XCTAssertEqual(calls.count, 1)
        XCTAssertNil(calls.first?.anchor ?? nil)
        XCTAssertEqual(calls.first?.onMainThread, true)
        XCTAssertEqual(events.get(), ["start", "registrant", "create", "complete"])
    }

    /// A box whose window has gone: validation, and nothing presented
    ///
    /// - Given: a box whose window was released before the ceremony
    /// - When:
    ///    - `associate` runs
    /// - Then:
    ///    - it throws `EngineAuthError.validation("presentationAnchor", …)`, from inside the runner
    ///    - no registrant is made, so no ceremony runs, and complete is not called
    ///
    func testAssociate_withAGoneWindow_throwsValidationWithoutPresenting() async {
        let box = await Self.goneWindowBox()
        let isEmpty = await MainActor.run { box.anchor == nil }
        XCTAssertTrue(isEmpty, "the window outlived its last strong reference")

        do {
            try await associate(anchor: box, ceremony: recordingRunner())
            XCTFail("Should have failed")
        } catch let error as EngineAuthError {
            guard case .validation(let field, let description, let recovery, let underlying) = error else {
                return XCTFail("Expected EngineAuthError.validation, got \(error)")
            }
            XCTAssertEqual(field, "presentationAnchor")
            XCTAssertEqual(description, WebAuthnCredentialOperations.presentationAnchorGoneDescription)
            XCTAssertEqual(recovery, WebAuthnCredentialOperations.presentationAnchorGoneRecovery)
            XCTAssertNil(underlying)
        } catch {
            XCTFail("Expected EngineAuthError, got \(error)")
        }
        XCTAssertEqual(events.get(), ["start", "runner-in", "runner-error"])
        XCTAssertEqual(factoryCalls.get().count, 0)
        XCTAssertEqual(registrant.createCallCount.get(), 0)
    }

    /// The runner's own errors are the caller's, rethrown unchanged
    ///
    /// - Given: a runner that refuses before the ceremony, and one that fails after it
    /// - When:
    ///    - `associate` runs with each
    /// - Then:
    ///    - each runner's own error is rethrown as it is, not re-expressed as an unknown service error
    ///    - the refusing runner runs no ceremony; neither reaches complete
    ///
    func testAssociate_runnerErrorsPassThroughUnchanged() async {
        await assertRunnerError(.refused) {
            try await self.associate(anchor: nil) { _ in throw RunnerOwnedError.refused }
        }
        XCTAssertEqual(registrant.createCallCount.get(), 0)

        await assertRunnerError(.afterCeremony) {
            try await self.associate(anchor: nil) { body in
                _ = try await body()
                throw RunnerOwnedError.afterCeremony
            }
        }
        XCTAssertEqual(registrant.createCallCount.get(), 1)
        XCTAssertFalse(events.get().contains("complete"))
    }

    /// The ceremony body converts its errors before the runner sees them
    ///
    /// - Given: a runner that records what its body throws, and a registrant that throws a `WebAuthnError`,
    ///   then one that throws an error with no engine form
    /// - When:
    ///    - `associate` runs with each
    /// - Then:
    ///    - the runner sees the `EngineAuthError` (the ceremony error's own, then the associate unknown
    ///      service error), and `associate` throws that same error
    ///
    func testAssociate_ceremonyErrorsReachTheRunnerAsEngineErrors() async {
        let ceremonyError = WebAuthnError.creationFailed(error: ASAuthorizationError(.failed))
        let seen = TestBox<[Error]>([])
        let runner: WebAuthnCredentialOperations.CeremonyRunner = { body in
            do {
                return try await body()
            } catch {
                seen.with { $0.append(error) }
                throw error
            }
        }

        registrant.mockedCreateResponse = .failure(ceremonyError)
        do {
            try await associate(anchor: nil, ceremony: runner)
            XCTFail("Should have failed")
        } catch {
            XCTAssertEqual(error as? EngineAuthError, ceremonyError.engineError)
        }
        XCTAssertEqual(seen.get().first as? EngineAuthError, ceremonyError.engineError)

        registrant.mockedCreateResponse = .failure(CancellationError())
        await assertUnknownServiceError(
            "An unknown error type was thrown by the service. Unable to associate WebAuthn credential."
        ) { try await self.associate(anchor: nil, ceremony: runner) }
        let second = seen.get().dropFirst().first
        guard case .service(let description, _, let underlying) = second as? EngineAuthError else {
            return XCTFail("The runner saw \(String(describing: second)), not an EngineAuthError.service")
        }
        XCTAssertEqual(
            description,
            "An unknown error type was thrown by the service. Unable to associate WebAuthn credential."
        )
        XCTAssertTrue(underlying is CancellationError, "\(String(describing: underlying))")
    }

    // MARK: - Support

    private enum RunnerOwnedError: Error, Equatable {
        case refused, afterCeremony
    }

    private func associate(
        anchor: EnginePresentationAnchorBox?,
        ceremony: @escaping WebAuthnCredentialOperations.CeremonyRunner
    ) async throws {
        let registrant: MockCredentialRegistrant = registrant
        let events = events
        let factoryCalls = factoryCalls
        let recordingRegistrant = RecordingRegistrant(wrapped: registrant, events: events)
        try await WebAuthnCredentialOperations.associate(
            accessToken: fixture.accessToken(),
            userPool: fixture.userPool(),
            anchor: anchor,
            ceremony: ceremony,
            registrant: { window in
                factoryCalls.with { $0.append((window.map { ObjectIdentifier($0) }, Thread.isMainThread)) }
                events.with { $0.append("registrant") }
                return recordingRegistrant
            }
        )
    }

    /// Records entering the runner, and leaving it with a value or an error.
    private func recordingRunner() -> WebAuthnCredentialOperations.CeremonyRunner {
        let events = events
        return { body in
            events.with { $0.append("runner-in") }
            do {
                let value = try await body()
                events.with { $0.append("runner-out") }
                return value
            } catch {
                events.with { $0.append("runner-error") }
                throw error
            }
        }
    }

    private func assertRunnerError(
        _ expected: RunnerOwnedError,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ body: () async throws -> Void
    ) async {
        do {
            try await body()
            XCTFail("Should have failed", file: file, line: line)
        } catch let error as RunnerOwnedError {
            XCTAssertEqual(error, expected, file: file, line: line)
        } catch {
            XCTFail("Expected the runner's own error, got \(error)", file: file, line: line)
        }
    }

    @MainActor
    private static func liveWindowBox() -> (EnginePresentationAnchor, EnginePresentationAnchorBox) {
        let window = EnginePresentationAnchor()
        return (window, EnginePresentationAnchorBox(window))
    }

    /// A box whose window (a fresh, never-shown `NSWindow`/`UIWindow`) was released inside an autorelease
    /// pool. That such a window deallocates on release was checked on macOS and on the iOS 26.5 simulator;
    /// the test's first assertion says so plainly if a platform ever keeps it alive.
    @MainActor
    private static func goneWindowBox() -> EnginePresentationAnchorBox {
        autoreleasepool {
            EnginePresentationAnchorBox(EnginePresentationAnchor())
        }
    }
}

/// Records `create` in the shared event list, then runs the wrapped mock.
@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
private struct RecordingRegistrant: CredentialRegistrantProtocol {
    let wrapped: MockCredentialRegistrant
    let events: TestBox<[String]>

    var presentationAnchor: EnginePresentationAnchor? {
        nil
    }

    func create(with options: CredentialCreationOptions) async throws -> CredentialRegistrationPayload {
        events.with { $0.append("create") }
        return try await wrapped.create(with: options)
    }
}
#endif
