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
final class DeleteWebAuthnCredentialTask: AuthDeleteWebAuthnCredentialTask, DefaultLogger, @unchecked Sendable {
    private let request: AuthDeleteWebAuthnCredentialRequest
    private let authStateMachine: AuthStateMachine
    private let userPoolFactory: UserPoolEnvironment.CognitoUserPoolFactory
    private let taskHelper: AWSAuthTaskHelper

    let eventName: HubPayloadEventName = HubPayload.EventName.Auth.deleteWebAuthnCredentialAPI

    init(
        request: AuthDeleteWebAuthnCredentialRequest,
        authStateMachine: AuthStateMachine,
        userPoolFactory: @escaping UserPoolEnvironment.CognitoUserPoolFactory
    ) {
        self.request = request
        self.authStateMachine = authStateMachine
        self.userPoolFactory = userPoolFactory
        self.taskHelper = AWSAuthTaskHelper(authStateMachine: authStateMachine)
    }

    /// The engine's `WebAuthnCredentialOperations.delete` does the work. It rethrows the token lookup's
    /// `AuthError` unchanged and re-expresses every other error as an `EngineAuthError`, which
    /// `AuthError(converting:)` bridges back to the `AuthError` this task has always thrown.
    func execute() async throws {
        do {
            await taskHelper.didStateMachineConfigured()
            try await WebAuthnCredentialOperations.delete(
                accessToken: { try await self.taskHelper.getAccessToken() },
                credentialId: request.credentialId,
                userPool: userPoolFactory
            )
        } catch {
            if let authError = AuthError(converting: error) {
                throw authError
            }
            let webAuthnError = WebAuthnError.unknown(
                message: WebAuthnCredentialOperations.deleteFailureMessage,
                error: error
            )
            throw webAuthnError.authError
        }
    }
}
