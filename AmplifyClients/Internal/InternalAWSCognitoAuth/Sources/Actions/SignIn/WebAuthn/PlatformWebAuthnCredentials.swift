//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import AuthenticationServices
import Foundation

/// - Note: `Sendable` because the WebAuthn actions holding these conform to `Action`, which is
///   `Sendable`.
package protocol WebAuthnCredentialsProtocol: Sendable {
    var presentationAnchor: EnginePresentationAnchor? { get }
}

@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
package protocol CredentialRegistrantProtocol: WebAuthnCredentialsProtocol {
    func create(with options: CredentialCreationOptions) async throws -> CredentialRegistrationPayload
}

@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
package protocol CredentialAsserterProtocol: WebAuthnCredentialsProtocol {
    func assert(with options: CredentialAssertionOptions) async throws -> CredentialAssertionPayload
}

// - MARK: WebAuthnCredentialsProtocol
/// Runs one platform WebAuthn ceremony at a time per operation (assertion, registration).
///
/// **The kept controller.** Each ceremony's `ASAuthorizationController` is kept, with its continuation,
/// until the delegate answers, so the ceremony can be cancelled: cancelling the task that awaits
/// `assert(with:)` or `create(with:)` calls `cancel()` on that controller, on the main actor. The delegate
/// then answers `.canceled`, which resumes the continuation with `WebAuthnError.assertionFailed` or
/// `.creationFailed` (`ASAuthorizationError.canceled`), as a user's own cancel does. A task that is
/// already cancelled when its ceremony would start presents nothing and throws the same error.
///
/// Each continuation is resumed exactly once. A pre-start cancel and an in-progress refusal resume a
/// continuation that never entered a slot. Every other continuation is in a slot, and only the delegate's
/// answer **from that ceremony's own controller** takes it out, under `lock`, before resuming it. So a
/// late or repeated answer finds the slot empty, and a stale controller's answer leaves a newer ceremony
/// alone. Taking it out also releases the controller.
///
/// `performRequests()` and `cancel()` both run on the main actor, so a cancel that arrives while a
/// ceremony is starting reaches the controller after `performRequests()`, never before it.
///
/// - Note: `final` and `@unchecked Sendable`: the slots are only read and written under `lock`.
@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
package final class PlatformWebAuthnCredentials: NSObject, WebAuthnCredentialsProtocol, @unchecked Sendable {
    private enum OperationType: String {
        case assert
        case register
    }

    /// Makes the controller for one ceremony. The default is `ASAuthorizationController`; a test passes
    /// one whose `performRequests()` presents nothing.
    package typealias ControllerFactory = @MainActor @Sendable (
        _ requests: [ASAuthorizationRequest]
    ) -> ASAuthorizationController

    /// One ceremony in flight: its continuation, and its controller, kept so it can be cancelled.
    /// `controller` is `nil` only while the slot is reserved and the controller is being made.
    private struct Ceremony<Payload> {
        let id: UInt64
        let continuation: CheckedContinuation<Payload, Error>
        var controller: ASAuthorizationController?
    }

    /// How a ceremony's start went.
    private enum Start {
        case reserved
        case alreadyInProgress
        case cancelled
    }

    package let presentationAnchor: EnginePresentationAnchor?
    private let makeController: ControllerFactory

    private let lock = NSLock()
    private var lastCeremonyId: UInt64 = 0
    private var assertion: Ceremony<CredentialAssertionPayload>?
    private var registration: Ceremony<CredentialRegistrationPayload>?

    package init(
        presentationAnchor: EnginePresentationAnchor?,
        makeController: @escaping ControllerFactory = { requests in
            ASAuthorizationController(authorizationRequests: requests)
        }
    ) {
        self.presentationAnchor = presentationAnchor
        self.makeController = makeController
    }

    /// Presents `request` through a kept controller and waits for the delegate's answer, cancelling the
    /// controller if the calling task is cancelled.
    @MainActor
    private func perform<Payload>(
        _ request: ASAuthorizationRequest,
        as operation: OperationType,
        in slot: ReferenceWritableKeyPath<PlatformWebAuthnCredentials, Ceremony<Payload>?>,
        inProgressMessage: String,
        cancelledError: Error
    ) async throws -> Payload {
        let id = lock.withLock {
            lastCeremonyId += 1
            return lastCeremonyId
        }
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let start: Start = lock.withLock {
                    guard self[keyPath: slot] == nil else {
                        return .alreadyInProgress
                    }
                    guard !Task.isCancelled else {
                        return .cancelled
                    }
                    self[keyPath: slot] = Ceremony(id: id, continuation: continuation, controller: nil)
                    return .reserved
                }

                switch start {
                case .reserved:
                    // Made outside `lock`, which the injected factory must not run under. Nothing can take
                    // the reserved slot meanwhile: only an answer from its own controller does, and the
                    // cancellation handler's main-actor hop runs after this synchronous block.
                    let controller = makeController([request])
                    lock.withLock { self[keyPath: slot]?.controller = controller }
                    controller.delegate = self
                    controller.presentationContextProvider = self
                    controller.performRequests()
                case .alreadyInProgress:
                    continuation.resume(throwing: WebAuthnError.unknown(message: inProgressMessage, error: nil))
                case .cancelled:
                    continuation.resume(throwing: cancelledError)
                }
            }
        } onCancel: {
            Task { @MainActor in
                self.cancelCeremony(id, of: operation)
            }
        }
    }

    /// Cancels ceremony `id`'s controller, if that ceremony is still in flight. The delegate answers.
    @MainActor
    private func cancelCeremony(_ id: UInt64, of operation: OperationType) {
        let controller: ASAuthorizationController? = lock.withLock {
            switch operation {
            case .assert:
                assertion?.id == id ? assertion?.controller : nil
            case .register:
                registration?.id == id ? registration?.controller : nil
            }
        }
        controller?.cancel()
    }

    /// Takes the assertion out of its slot, releasing its controller, if `controller` is the one it
    /// kept. `nil` if none is in flight, or if `controller` belongs to another (an earlier) ceremony.
    private func takeAssertion(answeredBy controller: ASAuthorizationController) -> Ceremony<CredentialAssertionPayload>? {
        lock.withLock {
            guard let ceremony = assertion, ceremony.controller === controller else {
                return nil
            }
            assertion = nil
            return ceremony
        }
    }

    /// Takes the registration out of its slot, releasing its controller, if `controller` is the one it
    /// kept. `nil` if none is in flight, or if `controller` belongs to another (an earlier) ceremony.
    private func takeRegistration(answeredBy controller: ASAuthorizationController) -> Ceremony<CredentialRegistrationPayload>? {
        lock.withLock {
            guard let ceremony = registration, ceremony.controller === controller else {
                return nil
            }
            registration = nil
            return ceremony
        }
    }
}

// - MARK: CredentialAsserterProtocol
@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
extension PlatformWebAuthnCredentials: CredentialAsserterProtocol {
    package func assert(with options: CredentialAssertionOptions) async throws -> CredentialAssertionPayload {
        let platformProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(
            relyingPartyIdentifier: options.relyingPartyId
        )

        let platformKeyRequest = try platformProvider.createCredentialAssertionRequest(
            challenge: options.challenge
        )

        return try await perform(
            platformKeyRequest,
            as: .assert,
            in: \.assertion,
            inProgressMessage: "There's a WebAuthn assertion already in progress",
            cancelledError: WebAuthnError.assertionFailed(error: ASAuthorizationError(.canceled))
        )
    }

    private func resumeAssertionContinuation(
        with result: CredentialAssertionPayload,
        from controller: ASAuthorizationController
    ) {
        takeAssertion(answeredBy: controller)?.continuation.resume(returning: result)
    }

    private func resumeAssertionContinuation(throwing error: any Error, from controller: ASAuthorizationController) {
        log.error("", error)
        takeAssertion(answeredBy: controller)?.continuation.resume(throwing: error)
    }

    private func resumeRegistrationContinuation(
        with result: CredentialRegistrationPayload,
        from controller: ASAuthorizationController
    ) {
        takeRegistration(answeredBy: controller)?.continuation.resume(returning: result)
    }

    private func resumeRegistrationContinuation(throwing error: any Error, from controller: ASAuthorizationController) {
        log.error("", error)
        takeRegistration(answeredBy: controller)?.continuation.resume(throwing: error)
    }
}

// - MARK: CredentialRegistrantProtocol
@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
extension PlatformWebAuthnCredentials: CredentialRegistrantProtocol {
    package func create(with options: CredentialCreationOptions) async throws -> CredentialRegistrationPayload {
        let platformProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(
            relyingPartyIdentifier: options.relyingParty.id
        )

        let platformKeyRequest = platformProvider.createCredentialRegistrationRequest(
            challenge: options.challenge,
            name: options.user.name,
            userID: options.user.id
        )
#if !os(visionOS)
        // `excludedCredentials` is not available on visionOS
        platformKeyRequest.excludedCredentials = options.excludeCredentials.compactMap { credential in
            return .init(credentialID: credential.id)
        }
#endif

        return try await perform(
            platformKeyRequest,
            as: .register,
            in: \.registration,
            inProgressMessage: "There's a WebAuthn registration already in progress",
            cancelledError: WebAuthnError.creationFailed(error: ASAuthorizationError(.canceled))
        )
    }
}

@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
package extension PlatformWebAuthnCredentials {
    /// No environment is in scope, so these lines go through the global router.
    static let log = EngineLog.logger(.category("PlatformWebAuthnCredentials"))

    var log: EngineLogger {
        Self.log
    }
}

// - MARK: ASAuthorizationControllerDelegate
@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
extension PlatformWebAuthnCredentials: ASAuthorizationControllerDelegate {
    package func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        switch authorization.credential {
        case let assertionCredential as ASAuthorizationPlatformPublicKeyCredentialAssertion:
            do {
                try resumeAssertionContinuation(with: .init(from: assertionCredential), from: controller)
            } catch {
                resumeAssertionContinuation(throwing: error, from: controller)
            }
        case let registrationCredential as ASAuthorizationPublicKeyCredentialRegistration:
            do {
                try resumeRegistrationContinuation(with: .init(from: registrationCredential), from: controller)
            } catch {
                resumeRegistrationContinuation(throwing: error, from: controller)
            }
        default:
            log.verbose("Unexpected type of credential: \(type(of: authorization.credential)).")
            handleUnexpectedResult(for: controller, throwing: nil)
        }
    }

    package func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: any Error
    ) {
        log.error("", error)
        guard let operationType = operationType(for: controller) else {
            // A controller with no WebAuthn request is never one this object kept, so neither ceremony is
            // resumed: each still waits for its own controller's answer. Both errors are still logged.
            resumeAssertionContinuation(
                throwing: EngineAuthError.unknown("Unable to assert WebAuthm Credential", error),
                from: controller
            )
            resumeRegistrationContinuation(
                throwing: EngineAuthError.unknown("Unable to register WebAuthm Credential", error),
                from: controller
            )
            return
        }

        guard let authorizationError = error as? ASAuthorizationError else {
            handleUnexpectedResult(for: operationType, from: controller, throwing: error)
            return
        }

        switch operationType {
        case .assert:
            log.verbose("Unable to assert existing credential")
            resumeAssertionContinuation(
                throwing: WebAuthnError.assertionFailed(error: authorizationError),
                from: controller
            )
        case .register:
            log.verbose("Unable to register new credential")
            resumeRegistrationContinuation(
                throwing: WebAuthnError.creationFailed(error: authorizationError),
                from: controller
            )
        }
    }

    private func operationType(for controller: ASAuthorizationController) -> OperationType? {
        for request in controller.authorizationRequests {
            if request is ASAuthorizationPlatformPublicKeyCredentialAssertionRequest {
                return .assert
            }
            if request is ASAuthorizationPublicKeyCredentialRegistrationRequest {
                return .register
            }
        }

        return nil
    }

    private func handleUnexpectedResult(
        for controller: ASAuthorizationController,
        throwing error: (any Error)?
    ) {
        if let operationType = operationType(for: controller) {
            handleUnexpectedResult(for: operationType, from: controller, throwing: error)
        }
    }

    private func handleUnexpectedResult(
        for operationType: OperationType,
        from controller: ASAuthorizationController,
        throwing error: (any Error)?
    ) {
        switch operationType {
        case .assert:
            resumeAssertionContinuation(
                throwing: EngineAuthError.unknown("Unable to assert WebAuthm Credential", error),
                from: controller
            )
        case .register:
            resumeRegistrationContinuation(
                throwing: EngineAuthError.unknown("Unable to register WebAuthm Credential", error),
                from: controller
            )
        }
    }
}

// - MARK: ASAuthorizationControllerPresentationContextProviding
@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
extension PlatformWebAuthnCredentials: ASAuthorizationControllerPresentationContextProviding {
    package func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return presentationAnchor ?? ASPresentationAnchor()
    }
}
#endif
