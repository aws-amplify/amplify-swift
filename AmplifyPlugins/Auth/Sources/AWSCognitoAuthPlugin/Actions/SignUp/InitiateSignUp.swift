//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSCognitoIdentityProvider

struct InitiateSignUp: Action {
    
    var identifier: String = "InitiateSignUp"
    let data: SignUpEventData
    let password: String?
    let attributes: [AuthUserAttribute]?
    
    func execute(
        withDispatcher dispatcher: any EventDispatcher,
        environment: any Environment
    ) async {
        logVerbose("\(#fileID) Starting execution", environment: environment)
        do {
            let authEnvironment = try environment.authEnvironment()
            let userPoolEnvironment = authEnvironment.userPoolEnvironment
            let client = try userPoolEnvironment.cognitoUserPoolFactory()
            let asfDeviceId = try await CognitoUserPoolASF.asfDeviceID(
                for: data.username,
                credentialStoreClient: authEnvironment.credentialsClient)
            let attributes = attributes?.reduce(
                into: [String: String]()) {
                    $0[$1.key.rawValue] = $1.value
                } ?? [:]
            let input = await SignUpInput(
                username: data.username,
                password: password,
                clientMetadata: data.clientMetadata,
                validationData: data.validationData,
                attributes: attributes,
                asfDeviceId: asfDeviceId,
                environment: userPoolEnvironment
            )

            let response = try await client.signUp(input: input)
            let dataToSend = SignUpEventData(
                username: data.username,
                clientMetadata: data.clientMetadata,
                validationData: data.validationData,
                session: response.session
            )
            logVerbose("\(#fileID) SignUp response succcess", environment: environment)
            let event: SignUpEvent
            if response.authResponse.isSignUpComplete {
                if let session = response.session {
                    event = SignUpEvent(eventType: .signedUp(dataToSend, .init(.completeAutoSignIn(session))))
                } else {
                    event = SignUpEvent(eventType: .signedUp(dataToSend, response.authResponse))
                }
            } else {
                event = SignUpEvent(eventType: .initiateSignUpComplete(dataToSend, response.authResponse))
            }
            await dispatcher.send(event)
        } catch let error as SignUpError {
            let errorEvent = SignUpEvent(eventType: .throwAuthError(error))
            logVerbose("\(#fileID) Sending event \(errorEvent)",
                       environment: environment)
            await dispatcher.send(errorEvent)
        } catch {
            let error = SignUpError.service(error: error)
            let errorEvent = SignUpEvent(eventType: .throwAuthError(error))
            logVerbose("\(#fileID) Sending event \(errorEvent)",
                       environment: environment)
            await dispatcher.send(errorEvent)
        }
    }
    
}

extension InitiateSignUp: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "signUpEventData": data.debugDictionary,
            "attributes": attributes
        ]
    }
}

extension InitiateSignUp: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
