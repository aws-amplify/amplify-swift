//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSCognitoIdentityProvider

struct AutoSignIn: Action {
    
    var identifier: String = "AutoSignIn"
    let signInEventData: SignInEventData
    let deviceMetadata: DeviceMetadata
    
    func execute(withDispatcher dispatcher: any EventDispatcher, environment: any Environment) async {
        do {
            let userPoolEnv = try environment.userPoolEnvironment()
            let authEnv = try environment.authEnvironment()
            
            guard let username = signInEventData.username else {
                logVerbose("\(#fileID) Unable to extract username from signInEventData", environment: environment)
                let authError = SignInError.inputValidation(field: "Unable to extract username")
                let event = SignInEvent(
                    eventType: .throwAuthError(authError)
                )
                await dispatcher.send(event)
                return
            }
            
            var authParameters = [
                "USERNAME": username
            ]
            
            let configuration = userPoolEnv.userPoolConfiguration
            let userPoolClientId = configuration.clientId

            if let clientSecret = configuration.clientSecret {
                let clientSecretHash = ClientSecretHelper.clientSecretHash(
                    username: username,
                    userPoolClientId: userPoolClientId,
                    clientSecret: clientSecret
                )
                authParameters["SECRET_HASH"] = clientSecretHash
            }
            
            if case .metadata(let data) = deviceMetadata {
                authParameters["DEVICE_KEY"] = data.deviceKey
            }
            
            let asfDeviceId = try await CognitoUserPoolASF.asfDeviceID(
                for: username,
                credentialStoreClient: authEnv.credentialsClient)
            
            var userContextData: CognitoIdentityProviderClientTypes.UserContextDataType?
            if let encodedData = await CognitoUserPoolASF.encodedContext(
                username: username,
                asfDeviceId: asfDeviceId,
                asfClient: userPoolEnv.cognitoUserPoolASFFactory(),
                userPoolConfiguration: configuration) {
                userContextData = .init(encodedData: encodedData)
            }
            let analyticsMetadata = userPoolEnv
                .cognitoUserPoolAnalyticsHandlerFactory()
                .analyticsMetadata()
            
            let request = InitiateAuthInput(
                analyticsMetadata: analyticsMetadata,
                authFlow: .userAuth,
                authParameters: authParameters,
                clientId: userPoolClientId,
                clientMetadata: signInEventData.clientMetadata,
                session: signInEventData.session,
                userContextData: userContextData
            )
            
            let responseEvent = try await sendRequest(
                request: request,
                username: username,
                environment: userPoolEnv)
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
    
    private func sendRequest(request: InitiateAuthInput,
                             username: String,
                             environment: UserPoolEnvironment) async throws -> StateMachineEvent {

        let cognitoClient = try environment.cognitoUserPoolFactory()
        logVerbose("\(#fileID) Starting execution", environment: environment)

        let response = try await cognitoClient.initiateAuth(input: request)
        return UserPoolSignInHelper.parseResponse(
            response,
            for: username,
            signInMethod: signInEventData.signInMethod,
            presentationAnchor: signInEventData.presentationAnchor
        )
    }
}

extension AutoSignIn: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "signInEventData": signInEventData.debugDictionary
        ]
    }
}

extension AutoSignIn: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
