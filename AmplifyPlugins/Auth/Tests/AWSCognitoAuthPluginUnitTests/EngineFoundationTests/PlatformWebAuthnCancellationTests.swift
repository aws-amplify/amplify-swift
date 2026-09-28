//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import AuthenticationServices
import struct AWSCognitoIdentityProvider.StartWebAuthnRegistrationOutput
import XCTest
@testable import InternalAWSCognitoAuth

/// `PlatformWebAuthnCredentials` keeps each ceremony's `ASAuthorizationController` until the delegate
/// answers, and cancels it when the awaiting task is cancelled.
///
/// The controllers here present nothing: `performRequests()` only records, and `cancel()` answers the
/// delegate with `.canceled` on the main actor, later, as the platform's does. A checked continuation
/// resumed twice traps, and one never resumed fails `assertCeremonyError`'s 5-second wait, so each
/// ceremony ending once is the exactly-once check. A late delegate answer after the ceremony checks
/// that its slot is empty.
@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
final class PlatformWebAuthnCancellationTests: XCTestCase {

    /// Registration: cancelling the task cancels the kept controller, and the delegate's `.canceled`
    /// resumes the ceremony once
    ///
    /// - Given: a registration whose controller has been presented
    /// - When:
    ///    - the awaiting task is cancelled
    /// - Then:
    ///    - `cancel()` is called once on that controller, on the main thread, after `performRequests()`
    ///    - the task throws `WebAuthnError.creationFailed(.canceled)`, the delegate's answer
    ///    - the controller is released, a late answer resumes nothing, and a new registration can start
    ///
    func testCancellingARegistration_cancelsTheKeptController_andResumesOnce() async throws {
        let recorder = ControllerRecorder()
        let credentials = recorder.credentials()
        let options = try Self.creationOptions()

        let presented = recorder.expectPerform()
        let task = Task { try await credentials.create(with: options) }
        await fulfillment(of: [presented], timeout: 5)
        task.cancel()

        await assertCeremonyError(.creationFailed(error: ASAuthorizationError(.canceled)), from: task)
        await MainActor.run {}
        XCTAssertEqual(recorder.events, ["make", "perform", "cancel"])
        XCTAssertTrue(recorder.allOnMainThread)
        XCTAssertNil(recorder.lastController, "the kept controller outlived its ceremony")

        // A late or repeated answer finds no ceremony in flight, so nothing is resumed a second time.
        await MainActor.run {
            credentials.authorizationController(
                controller: ASAuthorizationController(authorizationRequests: [Self.registrationRequest()]),
                didCompleteWithError: ASAuthorizationError(.canceled)
            )
        }

        // The slot is free: a new registration presents, and cancels the same way.
        let presentedAgain = recorder.expectPerform()
        let second = Task { try await credentials.create(with: options) }
        await fulfillment(of: [presentedAgain], timeout: 5)
        second.cancel()
        await assertCeremonyError(.creationFailed(error: ASAuthorizationError(.canceled)), from: second)
        XCTAssertEqual(recorder.events, ["make", "perform", "cancel", "make", "perform", "cancel"])
    }

    /// Assertion: cancelling the task cancels the kept controller, and the delegate's `.canceled`
    /// resumes the ceremony once
    ///
    /// - Given: an assertion whose controller has been presented
    /// - When:
    ///    - the awaiting task is cancelled
    /// - Then:
    ///    - `cancel()` is called once, on the main thread
    ///    - the task throws `WebAuthnError.assertionFailed(.canceled)`
    ///    - the controller is released
    ///
    func testCancellingAnAssertion_cancelsTheKeptController_andResumesOnce() async throws {
        let recorder = ControllerRecorder()
        let credentials = recorder.credentials()
        let options = try CredentialAssertionOptions(from: #"{"challenge":"Y2hhbGxlbmdl","rpId":"example.com"}"#)

        let presented = recorder.expectPerform()
        let task = Task { try await credentials.assert(with: options) }
        await fulfillment(of: [presented], timeout: 5)
        task.cancel()

        await assertCeremonyError(.assertionFailed(error: ASAuthorizationError(.canceled)), from: task)
        await MainActor.run {}
        XCTAssertEqual(recorder.events, ["make", "perform", "cancel"])
        XCTAssertTrue(recorder.allOnMainThread)
        XCTAssertNil(recorder.lastController, "the kept controller outlived its ceremony")
    }

    /// A task that is already cancelled presents nothing
    ///
    /// - Given: a task cancelled before its registration starts
    /// - When:
    ///    - it calls `create(with:)`
    /// - Then:
    ///    - no controller is made, presented or cancelled
    ///    - it throws `WebAuthnError.creationFailed(.canceled)`, as a cancelled sheet does
    ///
    func testAnAlreadyCancelledTask_presentsNothing_andThrowsCanceled() async throws {
        let recorder = ControllerRecorder()
        let credentials = recorder.credentials()
        let options = try Self.creationOptions()

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await credentials.create(with: options)
        }

        await assertCeremonyError(.creationFailed(error: ASAuthorizationError(.canceled)), from: task)
        // Let the cancellation handler's main-actor hop run: it finds no ceremony.
        await MainActor.run {}
        XCTAssertEqual(recorder.events, [])
    }

    /// The delegate's own answer ends the ceremony, and a cancel right after it does nothing
    ///
    /// - Given: a presented registration
    /// - When:
    ///    - in one main-actor turn, the delegate answers `.failed` on the kept controller and the task is
    ///      cancelled, so the cancellation handler fires while the task is still inside the ceremony
    /// - Then:
    ///    - the task throws `WebAuthnError.creationFailed(.failed)`
    ///    - the handler's hop finds no ceremony in flight: `cancel()` is never called
    ///    - the controller is released
    ///
    func testADelegateAnswer_endsTheCeremony_andALaterCancelDoesNothing() async throws {
        let recorder = ControllerRecorder()
        let credentials = recorder.credentials()
        let options = try Self.creationOptions()

        let presented = recorder.expectPerform()
        let task = Task { try await credentials.create(with: options) }
        await fulfillment(of: [presented], timeout: 5)
        await MainActor.run {
            guard let controller = recorder.lastController else {
                return XCTFail("No kept controller while the ceremony is in flight")
            }
            credentials.authorizationController(
                controller: controller,
                didCompleteWithError: ASAuthorizationError(.failed)
            )
            // `perform` is main-actor isolated, so the task cannot leave the ceremony (and its
            // cancellation handler) before this turn ends: the handler fires here.
            task.cancel()
        }

        await assertCeremonyError(.creationFailed(error: ASAuthorizationError(.failed)), from: task)
        await MainActor.run {}
        XCTAssertEqual(recorder.events, ["make", "perform"])
        XCTAssertNil(recorder.lastController, "the kept controller outlived its ceremony")
    }

    /// A stale controller's answer leaves a newer ceremony alone
    ///
    /// - Given: a registration that was cancelled and ended, whose controller is still held, and a newer
    ///   registration on the same object, presented through its own controller
    /// - When:
    ///    - the old controller answers `.failed`, then the newer task is cancelled
    /// - Then:
    ///    - the newer ceremony is not resumed by the old answer: it ends with its own controller's
    ///      `.canceled`, not with `.failed`
    ///
    func testAStaleControllersAnswer_doesNotResumeANewerCeremony() async throws {
        let recorder = ControllerRecorder()
        let credentials = recorder.credentials()
        let options = try Self.creationOptions()

        let presented = recorder.expectPerform()
        let first = Task { try await credentials.create(with: options) }
        await fulfillment(of: [presented], timeout: 5)
        // Held strongly, so the first ceremony's controller outlives it.
        let staleController = TestBox<ASAuthorizationController?>(recorder.lastController)
        first.cancel()
        await assertCeremonyError(.creationFailed(error: ASAuthorizationError(.canceled)), from: first)

        let presentedAgain = recorder.expectPerform()
        let second = Task { try await credentials.create(with: options) }
        await fulfillment(of: [presentedAgain], timeout: 5)
        await MainActor.run {
            guard let staleController = staleController.get(), staleController !== recorder.lastController else {
                return XCTFail("Expected the first ceremony's controller, distinct from the second's")
            }
            credentials.authorizationController(
                controller: staleController,
                didCompleteWithError: ASAuthorizationError(.failed)
            )
        }

        second.cancel()
        await assertCeremonyError(.creationFailed(error: ASAuthorizationError(.canceled)), from: second)
        XCTAssertEqual(recorder.events, ["make", "perform", "cancel", "make", "perform", "cancel"])
    }

    /// A second registration while one is in flight is refused, and the first is unaffected
    ///
    /// - Given: a presented registration
    /// - When:
    ///    - a second registration starts on the same object
    /// - Then:
    ///    - it throws the in-progress `WebAuthnError.unknown`, without making a controller
    ///    - cancelling the first still cancels its controller and resumes it
    ///
    func testASecondRegistration_isRefused_andTheFirstStillCancels() async throws {
        let recorder = ControllerRecorder()
        let credentials = recorder.credentials()
        let options = try Self.creationOptions()

        let presented = recorder.expectPerform()
        let first = Task { try await credentials.create(with: options) }
        await fulfillment(of: [presented], timeout: 5)

        do {
            _ = try await credentials.create(with: options)
            XCTFail("Should have failed")
        } catch let error as WebAuthnError {
            // `WebAuthnError.==` never matches two `.unknown` without an underlying error, so match the case.
            guard case .unknown(let message, let underlying) = error else {
                return XCTFail("Expected WebAuthnError.unknown, got \(error)")
            }
            XCTAssertEqual(message, "There's a WebAuthn registration already in progress")
            XCTAssertNil(underlying)
        } catch {
            XCTFail("Expected WebAuthnError, got \(error)")
        }

        first.cancel()
        await assertCeremonyError(.creationFailed(error: ASAuthorizationError(.canceled)), from: first)
        XCTAssertEqual(recorder.events, ["make", "perform", "cancel"])
    }

    // MARK: - Support

    /// Waits (at most 5 s, so a ceremony that is never resumed fails instead of hanging) for `task` to
    /// end, and checks that it threw `expected`.
    private func assertCeremonyError<Payload: Sendable>(
        _ expected: WebAuthnError,
        from task: Task<Payload, Error>,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let ended = XCTestExpectation(description: "the ceremony ended")
        let outcome = TestBox<Result<Payload, Error>?>(nil)
        Task {
            outcome.set(await task.result)
            ended.fulfill()
        }
        await fulfillment(of: [ended], timeout: 5)

        switch outcome.get() {
        case nil:
            XCTFail("The ceremony was never resumed", file: file, line: line)
        case .success:
            XCTFail("Should have failed", file: file, line: line)
        case .failure(let error as WebAuthnError):
            XCTAssertEqual(error, expected, file: file, line: line)
        case .failure(let error):
            XCTFail("Expected WebAuthnError, got \(error)", file: file, line: line)
        }
    }

    private static func creationOptions() throws -> CredentialCreationOptions {
        let output = StartWebAuthnRegistrationOutput(credentialCreationOptions: [
            "challenge": "Y2hhbGxlbmdl",
            "rp": ["id": "example.com"],
            "user": ["id": "dXNlcklk", "name": "User"],
            "excludeCredentials": []
        ])
        return try CredentialCreationOptions(from: output.credentialCreationOptions?.asStringMap())
    }

    private static func registrationRequest() -> ASAuthorizationRequest {
        ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: "example.com")
            .createCredentialRegistrationRequest(
                challenge: Data("challenge".utf8),
                name: "User",
                userID: Data("userId".utf8)
            )
    }
}

/// Makes the silent controllers and records what happens to them, in order.
///
/// - Note: `@unchecked Sendable`: every field is read and written under `lock`.
@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
private final class ControllerRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var recordedEvents: [String] = []
    private var onMainThread = true
    private var pendingPerform: XCTestExpectation?
    private weak var controller: ASAuthorizationController?

    var events: [String] {
        lock.withLock { recordedEvents }
    }

    var allOnMainThread: Bool {
        lock.withLock { onMainThread }
    }

    /// The last controller made, while something still holds it.
    var lastController: ASAuthorizationController? {
        lock.withLock { controller }
    }

    func credentials() -> PlatformWebAuthnCredentials {
        PlatformWebAuthnCredentials(presentationAnchor: nil) { requests in
            self.make(requests)
        }
    }

    /// Fulfilled by the next `performRequests()`.
    func expectPerform() -> XCTestExpectation {
        let expectation = XCTestExpectation(description: "performRequests")
        lock.withLock { pendingPerform = expectation }
        return expectation
    }

    func record(_ event: String, onMainThread isMainThread: Bool) {
        let expectation: XCTestExpectation? = lock.withLock {
            recordedEvents.append(event)
            onMainThread = onMainThread && isMainThread
            guard event == "perform" else {
                return nil
            }
            defer { pendingPerform = nil }
            return pendingPerform
        }
        expectation?.fulfill()
    }

    @MainActor
    private func make(_ requests: [ASAuthorizationRequest]) -> ASAuthorizationController {
        let controller = SilentAuthorizationController(authorizationRequests: requests)
        controller.recorder = self
        lock.withLock { self.controller = controller }
        record("make", onMainThread: Thread.isMainThread)
        return controller
    }
}

/// Presents nothing. `cancel()` answers the delegate with `.canceled` on the main actor, later, as the
/// platform's controller does.
///
/// - Note: `recorder` is set once, before the controller is used.
@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
private final class SilentAuthorizationController: ASAuthorizationController {
    var recorder: ControllerRecorder?

    override func performRequests() {
        recorder?.record("perform", onMainThread: Thread.isMainThread)
    }

    override func cancel() {
        recorder?.record("cancel", onMainThread: Thread.isMainThread)
        // Test-only: this controller is only touched on the main actor.
        nonisolated(unsafe) let controller = self
        Task { @MainActor in
            controller.delegate?.authorizationController?(
                controller: controller,
                didCompleteWithError: ASAuthorizationError(.canceled)
            )
        }
    }
}
#endif
