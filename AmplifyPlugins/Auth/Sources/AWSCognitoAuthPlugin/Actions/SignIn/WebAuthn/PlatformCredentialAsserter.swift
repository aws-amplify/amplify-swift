//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS)
import Amplify
import AuthenticationServices
import Foundation

@available(iOS 17.4, macOS 13.5, *)
protocol CredentialAsserterProtocol {
    var presentationAnchor: AuthUIPresentationAnchor? { get }

    func assert(with options: CredentialAssertionOptions) async throws -> CredentialAssertionPayload
}

@available(iOS 17.4, macOS 13.5, *)
class PlatformCredentialAsserter: NSObject, CredentialAsserterProtocol {
    let presentationAnchor: AuthUIPresentationAnchor?
    private var payloadContinuation: CheckedContinuation<CredentialAssertionPayload, Error>?

    init(presentationAnchor: AuthUIPresentationAnchor?) {
        self.presentationAnchor = presentationAnchor
    }

    func assert(with options: CredentialAssertionOptions) async throws -> CredentialAssertionPayload {
        let platformProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(
            relyingPartyIdentifier: options.relyingPartyId
        )

        let platformKeyRequest = platformProvider.createCredentialAssertionRequest(
            challenge: try options.challenge
        )

        return try await withCheckedThrowingContinuation { continuation in
            payloadContinuation = continuation
            let authController = ASAuthorizationController(
                authorizationRequests: [platformKeyRequest]
            )
            authController.delegate = self
            authController.presentationContextProvider = self
            authController.performRequests()
        }
    }

    private func resumeContinuation(with result: CredentialAssertionPayload) {
        payloadContinuation?.resume(returning: result)
        payloadContinuation = nil
    }

    private func resumeContinuation(throwing error: any Error) {
        log.error(error: error)
        payloadContinuation?.resume(throwing: error)
        payloadContinuation = nil
    }
}

@available(iOS 17.4, macOS 13.5, *)
extension PlatformCredentialAsserter: DefaultLogger {}

@available(iOS 17.4, macOS 13.5, *)
extension PlatformCredentialAsserter: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationPlatformPublicKeyCredentialAssertion else {
            log.verbose("Unexpected type of credential: \(type(of: authorization.credential)).")
            resumeContinuation(throwing: AuthError.unknown("Unable to assert WebAuthm Credential", nil))
            return
        }

        do {
            try resumeContinuation(with: .init(from: credential))
        } catch {
            log.error(error: error)
            resumeContinuation(throwing: error)
        }
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: any Error
    ) {
        log.error(error: error)
        guard let authorizationError = error as? ASAuthorizationError else {
            resumeContinuation(throwing: error)
            return
        }

        if case .canceled = authorizationError.code {
            resumeContinuation(throwing: WebAuthnError.userCancelled)
        } else {
            resumeContinuation(throwing: WebAuthnError.assertionFailed(error: authorizationError))
        }
    }
}

@available(iOS 17.4, macOS 13.5, *)
extension PlatformCredentialAsserter: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return presentationAnchor ?? ASPresentationAnchor()
    }
}
#endif
