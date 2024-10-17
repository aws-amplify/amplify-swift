//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS)
import Amplify
import AuthenticationServices
import AWSCognitoIdentityProvider
import Foundation

@available(iOS 17.4, macOS 13.5, *)
class AssociateWebAuthnCredentialTask: NSObject, AuthAssociateWebAuthnCredentialTask, DefaultLogger {
    private let request: AuthAssociateWebAuthnCredentialRequest
    private let authStateMachine: AuthStateMachine
    private let userPoolFactory: UserPoolEnvironment.CognitoUserPoolFactory
    private let taskHelper: AWSAuthTaskHelper
    private var payloadContinuation: CheckedContinuation<CredentialRegistrationPayload, Error>?

    let eventName: HubPayloadEventName = HubPayload.EventName.Auth.associateWebAuthnCredentialAPI

    init(
        request: AuthAssociateWebAuthnCredentialRequest,
        authStateMachine: AuthStateMachine,
        userPoolFactory: @escaping UserPoolEnvironment.CognitoUserPoolFactory
    ) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.userPoolFactory = userPoolFactory
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
    }

    func execute() async throws {
        do {
            await taskHelper.didStateMachineConfigured()
            let credential = try await createWebAuthnCredential(
                accessToken: taskHelper.getAccessToken(),
                userPoolService: userPoolFactory()
            )
            try await associateWebAuthCredential(
                credential: credential,
                accessToken: taskHelper.getAccessToken(),
                userPoolService: userPoolFactory()
            )
        } catch let error as AuthErrorConvertible {
            throw error.authError
        } catch {
            throw AuthError.unknown(
                "Unable to associate WebAuthn credential",
                error
            )
        }
    }

    private func createWebAuthnCredential(
        accessToken: String,
        userPoolService: CognitoUserPoolBehavior
    ) async throws -> String {
        let result = try await userPoolService.getWebAuthnRegistrationOptions(
            input: .init(accessToken: accessToken)
        )

        let options = try CredentialCreationOptions(
            from: result.credentialCreationOptions
        )

        let platformProvider = ASAuthorizationPlatformPublicKeyCredentialProvider(
            relyingPartyIdentifier: options.relyingParty.id
        )

        let platformKeyRequest = platformProvider.createCredentialRegistrationRequest(
            challenge: try options.challenge,
            name: options.user.name,
            userID: try options.user.id
        )
        platformKeyRequest.excludedCredentials = try options.excludeCredentials.compactMap { credential in
            return .init(credentialID: try credential.id)
        }

        let credential = try await withCheckedThrowingContinuation { continuation in
            payloadContinuation = continuation
            let authController = ASAuthorizationController(
                authorizationRequests: [platformKeyRequest]
            )
            authController.delegate = self
            authController.presentationContextProvider = self
            authController.performRequests()
        }

        return try credential.stringify()
    }

    private func associateWebAuthCredential(
        credential: String,
        accessToken: String,
        userPoolService: CognitoUserPoolBehavior
    ) async throws {
        _ = try await userPoolService.verifyWebAuthnRegistrationResult(
            input: .init(
                accessToken: accessToken,
                credential: credential
            )
        )
    }

    private func resumeContinuation(with result: CredentialRegistrationPayload) {
        payloadContinuation?.resume(returning: result)
        payloadContinuation = nil
    }

    private func resumeContinuation(throwing error: any Error) {
        log.error(error: error)
        payloadContinuation?.resume(throwing: error)
        payloadContinuation = nil
    }
}

// - MARK: ASAuthorizationControllerDelegate
@available(iOS 17.4, macOS 13.5, *)
extension AssociateWebAuthnCredentialTask: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationPublicKeyCredentialRegistration else {
            log.verbose("Unexpected type of credential: \(type(of: authorization.credential)).")
            resumeContinuation(throwing: AuthError.unknown("Unable to associate WebAuthm Credential", nil))
            return
        }

        do {
            try resumeContinuation(with: .init(from: credential))
        } catch {
            resumeContinuation(throwing: error)
        }
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: any Error
    ) {
        log.verbose("Unable to register new credential")
        if let authError = error as? AuthErrorConvertible {
            resumeContinuation(throwing: authError.authError)
            return
        }

        guard let authorizationError = error as? ASAuthorizationError else {
            resumeContinuation(throwing: AuthError.unknown("Unable to associate WebAuthm Credential", error))
            return
        }

        let authError: AuthError
        if case .canceled = authorizationError.code {
            authError = .service(
                AuthPluginErrorConstants.associateWebAuthnCredentialUserCancelledError.errorDescription,
                AuthPluginErrorConstants.associateWebAuthnCredentialUserCancelledError.recoverySuggestion,
                AWSCognitoAuthError.userCancelled
            )
        } else if isMatchedExcludedCredential(authorizationError.code) {
            authError = .service(
                AuthPluginErrorConstants.associateWebAuthnCredentialAlreadyExistError.errorDescription,
                AuthPluginErrorConstants.associateWebAuthnCredentialAlreadyExistError.recoverySuggestion,
                authorizationError
            )
        } else {
            authError = .unknown("Unable to associate WebAuthm Credential", error)
        }

        resumeContinuation(throwing: authError)
    }

    private func isMatchedExcludedCredential(_ code: ASAuthorizationError.Code) -> Bool {
        // ASAuthorizationError.matchedExcludedCredential is only defined in iOS 18
        if #available(iOS 18.0, *) {
            return code == .matchedExcludedCredential
        } else {
            return code.rawValue == 1006
        }
    }
}

// - MARK: ASAuthorizationControllerPresentationContextProviding
@available(iOS 17.4, macOS 13.5, *)
extension AssociateWebAuthnCredentialTask: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return request.presentationAnchor ?? ASPresentationAnchor()
    }
}
#endif
