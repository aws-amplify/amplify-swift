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

class DeleteWebAuthnCredentialTask: AuthDeleteWebAuthnCredentialTask, DefaultLogger {
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

    func execute() async throws {
        do {
            await taskHelper.didStateMachineConfigured()
            try await deleteWebAuthnCredential(
                credentialId: request.credentialId,
                accessToken: taskHelper.getAccessToken(),
                userPoolService: userPoolFactory()
            )
        } catch let error as AuthErrorConvertible {
            throw error.authError
        } catch {
            let webAuthnError = WebAuthnError.unknown(
                message: "Unable to delete WebAuthn credential",
                error: error
            )
            throw webAuthnError.authError
        }
    }

    private func deleteWebAuthnCredential(
        credentialId: String,
        accessToken: String,
        userPoolService: CognitoUserPoolBehavior
    ) async throws {
        _ = try await userPoolService.deleteWebAuthnCredential(
            input: .init(
                accessToken: accessToken,
                credentialId: credentialId
            )
        )
    }
}
