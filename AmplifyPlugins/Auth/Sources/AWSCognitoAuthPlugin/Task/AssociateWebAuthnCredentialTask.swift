//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(visionOS)
import Amplify
import AuthenticationServices
import AWSCognitoIdentityProvider
import Foundation

@available(iOS 17.4, macOS 13.5, visionOS 1.0, *)
class AssociateWebAuthnCredentialTask: NSObject, AuthAssociateWebAuthnCredentialTask, DefaultLogger {
    private let request: AuthAssociateWebAuthnCredentialRequest
    private let authStateMachine: AuthStateMachine
    private let userPoolFactory: UserPoolEnvironment.CognitoUserPoolFactory
    private let taskHelper: AWSAuthTaskHelper
    private let credentialRegistrant: CredentialRegistrantProtocol

    let eventName: HubPayloadEventName = HubPayload.EventName.Auth.associateWebAuthnCredentialAPI

    init(
        request: AuthAssociateWebAuthnCredentialRequest,
        authStateMachine: AuthStateMachine,
        userPoolFactory: @escaping UserPoolEnvironment.CognitoUserPoolFactory,
        registrantFactory: (AuthUIPresentationAnchor?) -> CredentialRegistrantProtocol = { anchor in
            PlatformWebAuthnCredentials(presentationAnchor: anchor)
        }
    ) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.userPoolFactory = userPoolFactory
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
        self.credentialRegistrant = registrantFactory(request.presentationAnchor)
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
            let webAuthnError = WebAuthnError.unknown(
                message: "Unable to associate WebAuthn credential",
                error: error
            )
            throw webAuthnError.authError
        }
    }

    private func createWebAuthnCredential(
        accessToken: String,
        userPoolService: CognitoUserPoolBehavior
    ) async throws -> Data {
        let result = try await userPoolService.startWebAuthnRegistration(
            input: .init(accessToken: accessToken)
        )

        let options = try CredentialCreationOptions(
            from: result.credentialCreationOptions?.asStringMap()
        )

        let credential = try await credentialRegistrant.create(with: options)
        return try credential.asData()
    }

    private func associateWebAuthCredential(
        credential: Data,
        accessToken: String,
        userPoolService: CognitoUserPoolBehavior
    ) async throws {
        _ = try await userPoolService.completeWebAuthnRegistration(
            input: .init(
                accessToken: accessToken,
                credential: .make(from: credential)
            )
        )
    }
}
#endif
