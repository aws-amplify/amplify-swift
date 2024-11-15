//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AuthenticationServices

extension AWSCognitoAuthPlugin: AuthCategoryWebAuthnBehaviour {
#if os(iOS) || os(macOS)
    @available(iOS 17.4, macOS 13.5, *)
    public func associateWebAuthnCredential(
        presentationAnchor: AuthUIPresentationAnchor? = nil,
        options: AuthAssociateWebAuthnCredentialRequest.Options? = nil
    ) async throws {
        let request = AuthAssociateWebAuthnCredentialRequest(
            presentationAnchor: presentationAnchor,
            options: options ?? .init()
        )
        let task = AssociateWebAuthnCredentialTask(
            request: request,
            authStateMachine: authStateMachine,
            userPoolFactory: authEnvironment.cognitoUserPoolFactory
        )

        _ = try await taskQueue.sync {
            try await task.value
        }
    }
#elseif os(visionOS)
    public func associateWebAuthnCredential(
        presentationAnchor: AuthUIPresentationAnchor,
        options: AuthAssociateWebAuthnCredentialRequest.Options? = nil
    ) async throws {
        let request = AuthAssociateWebAuthnCredentialRequest(
            presentationAnchor: presentationAnchor,
            options: options ?? .init()
        )
        let task = AssociateWebAuthnCredentialTask(
            request: request,
            authStateMachine: authStateMachine,
            userPoolFactory: authEnvironment.cognitoUserPoolFactory
        )

        _ = try await taskQueue.sync {
            try await task.value
        }
    }
#endif

    public func listWebAuthnCredentials(
        options: AuthListWebAuthnCredentialsRequest.Options? = nil
    ) async throws -> AuthListWebAuthnCredentialsResult {
        let request = AuthListWebAuthnCredentialsRequest(
            options: options ?? .init()
        )
        let task = ListWebAuthnCredentialsTask (
            request: request,
            authStateMachine: authStateMachine,
            userPoolFactory: authEnvironment.cognitoUserPoolFactory
        )

        let result = try await taskQueue.sync {
            try await task.value
        }

        guard let credentials = result as? AuthListWebAuthnCredentialsResult else {
            throw AuthError.unknown("Unable to create AuthListWebAuthnCredentialsResult from the result", nil)
        }
        return credentials
    }

    public func deleteWebAuthnCredential(
        credentialId: String,
        options: AuthDeleteWebAuthnCredentialRequest.Options? = nil
    ) async throws {
        let request = AuthDeleteWebAuthnCredentialRequest(
            credentialId: credentialId,
            options: options ?? .init()
        )
        let task = DeleteWebAuthnCredentialTask(
            request: request,
            authStateMachine: authStateMachine,
            userPoolFactory: authEnvironment.cognitoUserPoolFactory
        )

        _ = try await taskQueue.sync {
            try await task.value
        }
    }
}
