//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSCognitoIdentityProvider

struct InitiateUserAuth: Action {
    let identifier = "InitiateUserAuth"

    let signInEventData: SignInEventData
    let deviceMetadata: DeviceMetadata

    init(signInEventData: SignInEventData,
         deviceMetadata: DeviceMetadata) {
        self.signInEventData = signInEventData
        self.deviceMetadata = deviceMetadata
    }

    func execute(withDispatcher dispatcher: EventDispatcher,
                 environment: Environment) async {
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

            let preferredChallenge: String?
            if case .apiBased(let authFlow) = signInEventData.signInMethod,
               case .userAuth(let firstFactor) = authFlow {
                preferredChallenge = firstFactor?.challengeResponse
            } else {
                preferredChallenge = nil
            }

            let asfDeviceId = try await CognitoUserPoolASF.asfDeviceID(
                for: username,
                credentialStoreClient: authEnv.credentialsClient)
            let request = await InitiateAuthInput.userAuth(
                username: username,
                preferredChallenge: preferredChallenge,
                clientMetadata: signInEventData.clientMetadata,
                asfDeviceId: asfDeviceId,
                deviceMetadata: deviceMetadata,
                environment: userPoolEnv)

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
            signInMethod: signInEventData.signInMethod)
    }
}

extension InitiateUserAuth: DefaultLogger { }

extension InitiateUserAuth: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "signInEventData": signInEventData.debugDictionary,
            "deviceMetadata": deviceMetadata,
        ]
    }
}

extension InitiateUserAuth: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
