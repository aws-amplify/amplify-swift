//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSCognitoIdentityProvider

struct ConfirmSignUp: Action {
    
    var identifier: String = "ConfirmSignUp"
    let data: SignUpEventData
    let confirmationCode: String
    let forceAliasCreation: Bool?
    
    func execute(withDispatcher dispatcher: any EventDispatcher, environment: any Environment) async {
        do {
            let authEnvironment = try environment.authEnvironment()
            let userPoolEnvironment = authEnvironment.userPoolEnvironment
            let asfDeviceId = try await CognitoUserPoolASF.asfDeviceID(
                for: data.username,
                credentialStoreClient: authEnvironment.credentialsClient)
            let client = try userPoolEnvironment.cognitoUserPoolFactory()
            let input = await ConfirmSignUpInput(username: data.username,
                                                 confirmationCode: confirmationCode,
                                                 clientMetadata: data.clientMetadata,
                                                 asfDeviceId: asfDeviceId,
                                                 forceAliasCreation: forceAliasCreation,
                                                 session: data.session,
                                                 environment: userPoolEnvironment)
            let response = try await client.confirmSignUp(input: input)
            let dataToSend = SignUpEventData(
                username: data.username,
                clientMetadata: data.clientMetadata,
                validationData: data.validationData,
                session: response.session
            )
            logVerbose("\(#fileID) ConfirmSignUp response succcess", environment: environment)
            
            if let session = response.session {
                await dispatcher.send(SignUpEvent(eventType: .signedUp(dataToSend, .init(.completeAutoSignIn(session)))))
            } else {
                await dispatcher.send(SignUpEvent(eventType: .signedUp(dataToSend, .init(.done))))
            }
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

extension ConfirmSignUp: CustomDebugDictionaryConvertible {
    var debugDictionary: [String: Any] {
        [
            "identifier": identifier,
            "signUpEventData": data.debugDictionary,
            "confirmationCode": confirmationCode.masked(),
            "forceAliasCreation": forceAliasCreation
        ]
    }
}

extension ConfirmSignUp: CustomDebugStringConvertible {
    var debugDescription: String {
        debugDictionary.debugDescription
    }
}
