//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation
import InternalAWSCognitoAuth
import XCTest
@_spi(AmplifyExperimental) @testable import AmplifyCognitoClient
#if os(iOS) || os(macOS) || os(visionOS)
import AuthenticationServices

/// WebAuthn fixtures shared by the ceremony suites: Cognito's options, the ceremonies' results, and a passkey
/// sheet that presents nothing.
enum WebAuthnFixtures {

    /// `CREDENTIAL_REQUEST_OPTIONS` as Cognito sends it with a `WEB_AUTHN` challenge.
    static let requestOptions = #"{"challenge":"Y2hhbGxlbmdl","rpId":"example.com"}"#

    /// `StartWebAuthnRegistration`'s answer: options the engine can read.
    static func startRegistration() -> StartWebAuthnRegistrationOutput {
        .init(credentialCreationOptions: [
            "challenge": "Y2hhbGxlbmdl",
            "rp": ["id": "example.com"],
            "user": ["id": "dXNlcklk", "name": "alice"],
            "excludeCredentials": []
        ])
    }

    /// `StartWebAuthnRegistration`'s answer with options the engine cannot read (no challenge).
    static func unreadableRegistration() -> StartWebAuthnRegistrationOutput {
        .init(credentialCreationOptions: ["rp": ["id": "example.com"]])
    }

    /// A registration ceremony's result.
    @available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
    static let registration = CredentialRegistrationPayload(
        credentialId: "Y3JlZGVudGlhbA",
        attestationObject: "YXR0ZXN0YXRpb24",
        clientDataJSON: "Y2xpZW50RGF0YQ"
    )

    /// An assertion ceremony's result, as the platform would build it.
    @available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
    static func assertion() throws -> CredentialAssertionPayload {
        let json = #"""
        {"id":"Y3JlZGVudGlhbA","rawId":"Y3JlZGVudGlhbA","type":"public-key","authenticatorAttachment":"platform",
         "response":{"authenticatorData":"YXV0aA","clientDataJSON":"Y2xpZW50","signature":"c2ln","userHandle":"dXNlcklk"}}
        """#
        return try JSONDecoder().decode(CredentialAssertionPayload.self, from: Data(json.utf8))
    }

    /// The `CREDENTIAL` answer `RespondToAuthChallenge` carries for `assertion()`.
    @available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
    static func assertionAnswer() throws -> String {
        try assertion().stringify()
    }

    /// A fresh window, never shown.
    @MainActor
    static func window() -> ASPresentationAnchor {
        ASPresentationAnchor()
    }

    /// A box whose window has been released, so it unboxes to `nil` (checked on macOS and the iOS
    /// simulator: a never-shown window deallocates on release).
    @MainActor
    static func goneWindowBox() -> EnginePresentationAnchorBox {
        autoreleasepool {
            EnginePresentationAnchorBox(ASPresentationAnchor())
        }
    }
}

/// A passkey sheet that presents nothing: it records each ceremony (on which thread it was made, and over
/// which window), and answers with `answer`, which may wait on a gate or throw an `ASAuthorizationError`.
/// Serves as both the asserter and the registrant.
@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
final class FakePasskeySheet: CredentialAsserterProtocol, CredentialRegistrantProtocol, @unchecked Sendable {

    struct Ceremony: Sendable {
        let anchor: ASPresentationAnchor?
        let madeOnMainThread: Bool
    }

    // `@unchecked Sendable`: the properties below are only touched while holding `lock`.
    private let lock = NSLock()
    private var made: [Ceremony] = []
    private var ran = 0
    private var cancelledCeremonies = 0
    /// What a ceremony does before it answers.
    typealias Answer = @Sendable () async throws -> Void

    private var answer: Answer = {}
    private var ceremonyAnchor: ASPresentationAnchor?

    /// The asserter/registrant protocols read it; the fake records the window it was made with instead.
    var presentationAnchor: EnginePresentationAnchor? {
        lock.withLock { ceremonyAnchor }
    }

    /// Every ceremony made, in order.
    var ceremonies: [Ceremony] {
        lock.withLock { made }
    }

    /// How many ceremonies started, and how many ended because their task was cancelled (the kept
    /// controller's cancel, as `PlatformWebAuthnCredentials` does it).
    var started: Int {
        lock.withLock { ran }
    }

    var cancelled: Int {
        lock.withLock { cancelledCeremonies }
    }

    /// What each ceremony does before it answers: return, wait, or throw.
    func answer(with body: @escaping @Sendable () async throws -> Void) {
        lock.withLock { answer = body }
    }

    /// Answers every ceremony with the platform's error for `code`, as the delegate does.
    func fail(with code: ASAuthorizationError.Code) {
        answer { throw ASAuthorizationError(code) }
    }

    /// The factories the live engine takes, which make this sheet.
    var factories: LiveWebAuthnCeremonies {
        LiveWebAuthnCeremonies(
            makeAsserter: { [self] anchor in record(anchor) },
            makeRegistrant: { [self] anchor in record(anchor) }
        )
    }

    @MainActor
    private func record(_ anchor: ASPresentationAnchor?) -> FakePasskeySheet {
        lock.withLock {
            made.append(Ceremony(anchor: anchor, madeOnMainThread: Thread.isMainThread))
            ceremonyAnchor = anchor
        }
        return self
    }

    func assert(with options: CredentialAssertionOptions) async throws -> CredentialAssertionPayload {
        try await perform(WebAuthnError.assertionFailed)
        return try WebAuthnFixtures.assertion()
    }

    func create(with options: CredentialCreationOptions) async throws -> CredentialRegistrationPayload {
        try await perform(WebAuthnError.creationFailed)
        return WebAuthnFixtures.registration
    }

    /// Runs the answer. A cancelled task ends with `.canceled`, as the kept controller's delegate answers.
    private func perform(_ failure: (ASAuthorizationError) -> WebAuthnError) async throws {
        let body: Answer = lock.withLock {
            ran += 1
            return answer
        }
        do {
            try await body()
            try Task.checkCancellation()
        } catch is CancellationError {
            lock.withLock { cancelledCeremonies += 1 }
            throw failure(ASAuthorizationError(.canceled))
        } catch let error as ASAuthorizationError {
            throw failure(error)
        }
    }
}

extension LiveEngineHarness {

    /// The live engine with `sheet` in place of the platform's passkey sheet.
    @available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
    func engine(sheet: FakePasskeySheet) throws -> LiveSessionEngine {
        try LiveSessionEngine(resources: resources(), webAuthnCeremonies: sheet.factories)
    }

    /// Clients over this harness's live engines (one per session, with `sheet`), and `clientHarness`'s
    /// registry, keychain and sheet lock.
    @available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
    func dependencies(
        _ clientHarness: ClientHarness,
        sheet: FakePasskeySheet,
        lock: SystemSheetLock? = nil
    ) -> SessionCoreDependencies {
        var dependencies = clientHarness.dependencies
        let base = dependencies
        dependencies = SessionCoreDependencies(
            registry: base.registry,
            gates: base.gates,
            makeStore: base.makeStore,
            makeClients: base.makeClients,
            makeEngine: { [self] _ in try engine(sheet: sheet) },
            makeRevoker: base.makeRevoker,
            scheduleRestore: base.scheduleRestore,
            bounds: base.bounds,
            now: { Date() }
        )
        dependencies.sheetLock = lock ?? clientHarness.sheetLock
        return dependencies
    }
}

/// Holds a passkey sheet up until the test lets it answer, and says when it went up.
actor HeldSheet {

    private let up = Gate(isOpen: true)
    private let release = Gate()

    /// The sheet's answer: says it is up, then waits (cancellation ends the wait, as `cancel()` does).
    nonisolated var answer: @Sendable () async throws -> Void {
        { [up, release] in
            await up.pass()
            try await withTaskCancellationHandler {
                await release.pass()
            } onCancel: {
                Task { await release.open() }
            }
            try Task.checkCancellation()
        }
    }

    func waitUntilUp(_ count: Int = 1) async {
        await up.waitForArrivals(count)
    }

    func letAnswer() async {
        await release.open()
    }
}
#endif

/// A value a test's `@Sendable` closures share, behind a lock.
final class TestBox<Value>: @unchecked Sendable {

    // `@unchecked Sendable`: `stored` is only touched while holding `lock`.
    private let lock = NSLock()
    private var stored: Value

    init(_ value: Value) {
        self.stored = value
    }

    var value: Value {
        lock.withLock { stored }
    }

    func with<Result>(_ body: (inout Value) -> Result) -> Result {
        lock.withLock { body(&stored) }
    }
}

#if os(iOS) || os(macOS) || os(visionOS)
extension EnginePresentationAnchorBox {

    /// Whether this box holds `window` (read on the main actor, as the box requires).
    @MainActor
    func holds(_ window: ASPresentationAnchor) -> Bool {
        anchor === window
    }
}
#endif

// MARK: Bounded waits

/// A wait that did not end in time.
struct WaitTimedOut: Error, CustomStringConvertible {
    let description: String
}

/// Runs `body`, failing with `WaitTimedOut` if it has not finished within `seconds`, so a test that would hang
/// fails instead.
///
/// `body` runs in an unstructured task, raced against a timer through a continuation resumed once, by
/// whichever ends first. So the bound holds even for a wait that ignores cancellation (`Gate.waitForArrivals`,
/// `HeldSheet.waitUntilUp`, `Task.value`): a task group would wait for such a child to end. On a timeout the
/// body's task is cancelled and left to finish, or not, on its own; the test has failed by then. The caller's
/// cancellation is forwarded to the body's task. Any `T` works, an optional one included: the outcome is carried
/// as a `Result`, never as a `nil`.
func withinTime<T: Sendable>(
    _ seconds: Double = 10,
    _ what: String,
    _ body: @escaping @Sendable () async throws -> T
) async throws -> T {
    let race = ResumeOnce<T>()
    let work = Task { race.resume(with: await Result { try await body() }) }
    let timer = Task {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        race.resume(with: .failure(WaitTimedOut(description: "\(what) did not happen within \(seconds) s")))
    }
    let outcome = await withTaskCancellationHandler {
        await race.value
    } onCancel: {
        work.cancel()
    }
    work.cancel()
    timer.cancel()
    return try outcome.get()
}

/// A continuation resumed once, by the first of several answers; later answers are ignored.
private final class ResumeOnce<T: Sendable>: @unchecked Sendable {

    // `@unchecked Sendable`: every property is only touched while holding `lock`.
    private let lock = NSLock()
    private var outcome: Result<T, Error>?
    private var continuation: CheckedContinuation<Result<T, Error>, Never>?

    func resume(with result: Result<T, Error>) {
        let waiting: CheckedContinuation<Result<T, Error>, Never>? = lock.withLock {
            guard outcome == nil else {
                return nil
            }
            outcome = result
            defer { continuation = nil }
            return continuation
        }
        waiting?.resume(returning: result)
    }

    var value: Result<T, Error> {
        get async {
            await withCheckedContinuation { continuation in
                let ready: Result<T, Error>? = lock.withLock {
                    if let outcome {
                        return outcome
                    }
                    self.continuation = continuation
                    return nil
                }
                if let ready {
                    continuation.resume(returning: ready)
                }
            }
        }
    }
}

private extension Result where Failure == Error {

    /// `Result(catching:)` for an async body.
    init(_ body: () async throws -> Success) async {
        do {
            self = try await .success(body())
        } catch {
            self = .failure(error)
        }
    }
}

extension Task where Failure == Error {

    /// The task's value, or `WaitTimedOut` after `seconds`.
    func value(within seconds: Double = 10) async throws -> Success {
        try await withinTime(seconds, "the task's end") { try await self.value }
    }
}

extension Gate {

    /// `waitForArrivals(_:)`, failing with `WaitTimedOut` after `seconds`.
    func arrivals(_ count: Int, within seconds: Double = 10) async throws {
        try await withinTime(seconds, "\(count) arrivals at the gate") { await self.waitForArrivals(count) }
    }
}

#if os(iOS) || os(macOS) || os(visionOS)
extension HeldSheet {

    /// `waitUntilUp(_:)`, failing with `WaitTimedOut` after `seconds`.
    func up(_ count: Int = 1, within seconds: Double = 10) async throws {
        try await withinTime(seconds, "the passkey sheet going up") { await self.waitUntilUp(count) }
    }
}
#endif
