//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import Amplify
import AuthenticationServices
import Foundation

protocol WebAuthnCredentialsProtocol {
    var presentationAnchor: AuthUIPresentationAnchor? { get }
}

@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
protocol CredentialRegistrantProtocol: WebAuthnCredentialsProtocol {
    func create(with options: CredentialCreationOptions) async throws -> CredentialRegistrationPayload
}

@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
protocol CredentialAsserterProtocol: WebAuthnCredentialsProtocol {
    func assert(with options: CredentialAssertionOptions) async throws -> CredentialAssertionPayload
}

// - MARK: WebAuthnCredentialsProtocol
@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
class PlatformWebAuthnCredentials: NSObject, WebAuthnCredentialsProtocol {
    private enum OperationType: String {
        case assert
        case register
    }

    let presentationAnchor: AuthUIPresentationAnchor?
    private var assertionContinuation: CheckedContinuation<CredentialAssertionPayload, Error>?
    private var registrationContinuation: CheckedContinuation<CredentialRegistrationPayload, Error>?

    init(presentationAnchor: AuthUIPresentationAnchor?) {
        self.presentationAnchor = presentationAnchor
    }
}

// - MARK: CredentialAsserterProtocol
@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
extension PlatformWebAuthnCredentials: CredentialAsserterProtocol {
    func assert(with options: CredentialAssertionOptions) async throws -> CredentialAssertionPayload {
        guard assertionContinuation == nil else {
            throw WebAuthnError.unknown(
                message: "There's a WebAuthn assertion already in progress",
                error: nil
            )
        }

        let platformProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(
            relyingPartyIdentifier: options.relyingPartyId
        )

        let platformKeyRequest = platformProvider.createCredentialAssertionRequest(
            challenge: try options.challenge
        )

        return try await withCheckedThrowingContinuation { continuation in
            assertionContinuation = continuation
            let authController = ASAuthorizationController(
                authorizationRequests: [platformKeyRequest]
            )
            authController.delegate = self
            authController.presentationContextProvider = self
            authController.performRequests()
        }
    }

    private func resumeAssertionContinuation(with result: CredentialAssertionPayload) {
        assertionContinuation?.resume(returning: result)
        assertionContinuation = nil
    }

    private func resumeAssertionContinuation(throwing error: any Error) {
        log.error(error: error)
        assertionContinuation?.resume(throwing: error)
        assertionContinuation = nil
    }

    private func resumeRegistrationContinuation(with result: CredentialRegistrationPayload) {
        registrationContinuation?.resume(returning: result)
        registrationContinuation = nil
    }

    private func resumeRegistrationContinuation(throwing error: any Error) {
        log.error(error: error)
        registrationContinuation?.resume(throwing: error)
        registrationContinuation = nil
    }
}

// - MARK: CredentialRegistrantProtocol
@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
extension PlatformWebAuthnCredentials: CredentialRegistrantProtocol {
    func create(with options: CredentialCreationOptions) async throws -> CredentialRegistrationPayload {
        guard registrationContinuation == nil else {
            throw WebAuthnError.unknown(
                message: "There's a WebAuthn registration already in progress",
                error: nil
            )
        }
        let platformProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(
            relyingPartyIdentifier: options.relyingParty.id
        )

        let platformKeyRequest = platformProvider.createCredentialRegistrationRequest(
            challenge: options.challenge,
            name: options.user.name,
            userID: options.user.id
        )
        platformKeyRequest.excludedCredentials = options.excludeCredentials.compactMap { credential in
            return .init(credentialID: credential.id)
        }

        return try await withCheckedThrowingContinuation { continuation in
            registrationContinuation = continuation
            let authController = ASAuthorizationController(
                authorizationRequests: [platformKeyRequest]
            )
            authController.delegate = self
            authController.presentationContextProvider = self
            authController.performRequests()
        }
    }
}

@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
extension PlatformWebAuthnCredentials: DefaultLogger {}

// - MARK: ASAuthorizationControllerDelegate
@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
extension PlatformWebAuthnCredentials: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        switch authorization.credential {
        case let assertionCredential as ASAuthorizationPlatformPublicKeyCredentialAssertion:
            do {
                try resumeAssertionContinuation(with: .init(from: assertionCredential))
            } catch {
                resumeAssertionContinuation(throwing: error)
            }
        case let registrationCredential as ASAuthorizationPublicKeyCredentialRegistration:
            do {
                try resumeRegistrationContinuation(with: .init(from: registrationCredential))
            } catch {
                resumeRegistrationContinuation(throwing: error)
            }
        default:
            log.verbose("Unexpected type of credential: \(type(of: authorization.credential)).")
            handleUnexpectedResult(for: controller, throwing: nil)
        }
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: any Error
    ) {
        log.error(error: error)
        guard let operationType = operationType(for: controller) else {
            // In the extremely unlikely scenario in which this happens, resume all continuations to prevent blocking the app
            resumeAssertionContinuation(throwing: AuthError.unknown("Unable to assert WebAuthm Credential", error))
            resumeRegistrationContinuation(throwing: AuthError.unknown("Unable to register WebAuthm Credential", error))
            return
        }

        guard let authorizationError = error as? ASAuthorizationError else {
            handleUnexpectedResult(for: operationType, throwing: error)
            return
        }

        switch operationType {
        case .assert:
            log.verbose("Unable to assert existing credential")
            resumeAssertionContinuation(
                throwing: WebAuthnError.assertionFailed(error: authorizationError)
            )
        case .register:
            log.verbose("Unable to register new credential")
            resumeRegistrationContinuation(
                throwing: WebAuthnError.creationFailed(error: authorizationError)
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
            handleUnexpectedResult(for: operationType, throwing: error)
        }
    }

    private func handleUnexpectedResult(
        for operationType: OperationType,
        throwing error: (any Error)?
    ) {
        switch operationType {
        case .assert:
            resumeAssertionContinuation(
                throwing: AuthError.unknown("Unable to assert WebAuthm Credential", error)
            )
        case .register:
            resumeRegistrationContinuation(
                throwing: AuthError.unknown("Unable to register WebAuthm Credential", error)
            )
        }
    }
}

// - MARK: ASAuthorizationControllerPresentationContextProviding
@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
extension PlatformWebAuthnCredentials: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return presentationAnchor ?? ASPresentationAnchor()
    }
}
#endif
