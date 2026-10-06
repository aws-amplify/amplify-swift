//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation

package struct InitiateCustomAuth: Action {
    package let identifier = "InitiateCustomAuth"

    package let username: String
    package let clientMetadata: [String: String]
    package let deviceMetadata: DeviceMetadata

    package init(
        username: String,
        clientMetadata: [String: String],
        deviceMetadata: DeviceMetadata
    ) {
        self.username = username
        self.clientMetadata = clientMetadata
        self.deviceMetadata = deviceMetadata
    }

    package func execute(
        withDispatcher dispatcher: EventDispatcher,
        environment: Environment
    ) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)
        do {
            let userPoolEnv = try environment.userPoolEnvironment()
            let authEnv = try environment.authEnvironment()
            let asfDeviceId = try await CognitoUserPoolASF.asfDeviceID(
                for: username,
                credentialStoreClient: authEnv.credentialsClient
            )
            let request = await InitiateAuthInput.customAuth(
                username: username,
                clientMetadata: clientMetadata,
                asfDeviceId: asfDeviceId,
                deviceMetadata: deviceMetadata,
                environment: userPoolEnv
            )

            let responseEvent = try await sendRequest(
                request: request,
                environment: userPoolEnv,
                logger: environment.engineLogger
            )
            logVerbose("\(#fileID) Sending event \(responseEvent)", environment: environment)
            await dispatcher.send(responseEvent)

        } catch let error as SignInError {
            logVerbose("\(#fileID) Raised error \(error)", environment: environment)
            let event = SignInEvent(eventType: .throwAuthError(error))
            await dispatcher.send(event)
        } catch {
            logVerbose("\(#fileID) Caught error \(error)", environment: environment)
            let authError = SignInError.service(error: error)
            let event = SignInEvent(
                eventType: .throwAuthError(authError)
            )
            await dispatcher.send(event)
        }

    }

    private func sendRequest(
        request: InitiateAuthInput,
        environment: UserPoolEnvironment,
        logger: any EngineScopedLogger
    ) async throws -> StateMachineEvent {

        let cognitoClient = try environment.cognitoUserPoolFactory()
        logVerbose("\(#fileID) Starting execution", environment: environment)

        let response = try await cognitoClient.initiateAuth(input: request)
        return UserPoolSignInHelper.parseResponse(
            response,
            for: username,
            signInMethod: .apiBased(.customWithoutSRP),
            logger: logger
        )
    }

}

extension InitiateCustomAuth: CustomDebugDictionaryConvertible {
    package var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "username": username.maskedForLog()
        ]
    }
}

extension InitiateCustomAuth: CustomDebugStringConvertible {
    package var debugDescription: String {
        debugDictionary.debugDescription
    }
}
