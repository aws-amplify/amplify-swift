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

class ListWebAuthnCredentialsTask: AuthListWebAuthnCredentialsTask, DefaultLogger {
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

    func execute() async throws -> AuthListWebAuthnCredentialsResult {
        do {
            await taskHelper.didStateMachineConfigured()
            return try await listWebAuthnCredentials(
                accessToken: taskHelper.getAccessToken(),
                userPoolService: userPoolFactory()
            )
        } catch let error as AuthErrorConvertible {
            throw error.authError
        } catch {
            let webAuthnError = WebAuthnError.unknown(
                message: "Unable to list WebAuthn credentials",
                error: error
            )
            throw webAuthnError.authError
        }
    }

    private func listWebAuthnCredentials(
        accessToken: String,
        userPoolService: CognitoUserPoolBehavior
    ) async throws -> AuthListWebAuthnCredentialsResult {
        let result = try await userPoolService.listWebAuthnCredentials(
            input: .init(
                accessToken: accessToken,
                maxResults: Int(request.options.pageSize),
                nextToken: request.options.nextToken
            )
        )

        let credentialDescriptions = result.credentials ?? []
        let webAuthnCredentials: [AuthWebAuthnCredential] = credentialDescriptions.compactMap { credential in
            // All of these are marked as required but the Swift SDK doesn't respect that and maps them to Optionals
            guard let createdAt = credential.createdAt,
                  let credentialId = credential.credentialId,
                  let relyingPartyId = credential.relyingPartyId else {
                return nil
            }

            return AWSCognitoWebAuthnCredential(
                credentialId: credentialId,
                createdAt: createdAt,
                relyingPartyId: relyingPartyId,
                friendlyName: friendlyName(from: credential)
            )
        }

        return .init(
            credentials: webAuthnCredentials,
            nextToken: result.nextToken
        )
    }

    private func friendlyName(
        from credential: CognitoIdentityProviderClientTypes.WebAuthnCredentialDescription
    ) -> String? {
        guard let friendlyName = credential.friendlyCredentialName, !friendlyName.isEmpty else {
            return nil
        }

        return friendlyName
    }
}
