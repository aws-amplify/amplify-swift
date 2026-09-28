//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSCognitoIdentityProvider
import AWSPluginsCore
import Foundation
import InternalAWSCognitoAuth

/// - Note: `final` and `@unchecked Sendable`: the task is constructed, run once, and discarded.
final class ListWebAuthnCredentialsTask: AuthListWebAuthnCredentialsTask, DefaultLogger, @unchecked Sendable {
    private let request: AuthListWebAuthnCredentialsRequest
    private let authStateMachine: AuthStateMachine
    private let userPoolFactory: UserPoolEnvironment.CognitoUserPoolFactory
    private let taskHelper: AWSAuthTaskHelper

    let eventName: HubPayloadEventName = HubPayload.EventName.Auth.listWebAuthnCredentialsAPI

    init(
        request: AuthListWebAuthnCredentialsRequest,
        authStateMachine: AuthStateMachine,
        userPoolFactory: @escaping UserPoolEnvironment.CognitoUserPoolFactory
    ) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.userPoolFactory = userPoolFactory
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
    }

    /// The engine's `WebAuthnCredentialOperations.list` does the work. It rethrows the token lookup's
    /// `AuthError` unchanged and re-expresses every other error as an `EngineAuthError`, which
    /// `AuthError(converting:)` bridges back to the `AuthError` this task has always thrown.
    func execute() async throws -> AuthListWebAuthnCredentialsResult {
        do {
            await taskHelper.didStateMachineConfigured()
            let page = try await WebAuthnCredentialOperations.list(
                accessToken: { try await self.taskHelper.getAccessToken() },
                pageSize: request.options.pageSize,
                nextToken: request.options.nextToken,
                userPool: userPoolFactory
            )
            return result(from: page)
        } catch {
            if let authError = AuthError(converting: error) {
                throw authError
            }
            let webAuthnError = WebAuthnError.unknown(
                message: WebAuthnCredentialOperations.listFailureMessage,
                error: error
            )
            throw webAuthnError.authError
        }
    }

    private func result(from page: EngineWebAuthnCredentialPage) -> AuthListWebAuthnCredentialsResult {
        let webAuthnCredentials: [AuthWebAuthnCredential] = page.credentials.map { credential in
            AWSCognitoWebAuthnCredential(
                credentialId: credential.credentialId,
                createdAt: credential.createdAt,
                relyingPartyId: credential.relyingPartyId,
                friendlyName: credential.friendlyName
            )
        }

        return .init(
            credentials: webAuthnCredentials,
            nextToken: page.nextToken
        )
    }
}
