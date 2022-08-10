//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import CryptoKit
import AWSCognitoIdentityProvider
import Amplify

struct InitiateSignUp: Action {
    let identifier = "InitiateSignUp"

    let signUpEventData: SignUpEventData

    init(signUpEventData: SignUpEventData) {
        self.signUpEventData = signUpEventData
    }

    func execute(
        withDispatcher dispatcher: EventDispatcher,
        environment: Environment
    ) {
        logVerbose("\(#fileID) Starting execution", environment: environment)
        guard let authEnvironment = environment as? AuthEnvironment,
              let environment = environment as? UserPoolEnvironment else {
            let message = AuthPluginErrorConstants.configurationError
            let authError = AuthenticationError.configuration(message: message)
            let event = SignUpEvent(
                id: UUID().uuidString,
                eventType: .throwAuthError(authError)
            )
            dispatcher.send(event)
            return
        }

        let client: CognitoUserPoolBehavior
        do {
            client = try environment.cognitoUserPoolFactory()
        } catch {
            let authError = AuthenticationError.configuration(message: "Failed to get CognitoUserPool client: \(error)")
            let event = SignUpEvent(
                id: UUID().uuidString,
                eventType: .throwAuthError(authError)
            )
            dispatcher.send(event)
            return
        }


        logVerbose("\(#fileID) Starting signup", environment: environment)

        Task {
            let event: SignUpEvent
            do {
                let asfDeviceId = try? await CognitoUserPoolASF.asfDeviceID(
                    for: signUpEventData.username,
                    credentialStoreClient: authEnvironment.credentialStoreClientFactory())

                let input = SignUpInput(username: signUpEventData.username,
                                        password: signUpEventData.password,
                                        attributes: signUpEventData.attributes,
                                        asfDeviceId: asfDeviceId,
                                        environment: environment)
                let response = try await client.signUp(input: input)
                logVerbose("\(#fileID) SignUp received", environment: environment)
                event = SignUpEvent(eventType: .initiateSignUpSuccess(
                                    username: signUpEventData.username,
                                    signUpResponse: response))
            } catch {
                let error = SignUpError.service(error: error)
                event = SignUpEvent(eventType: .initiateSignUpFailure(error: error))
            }
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            dispatcher.send(event)
        }
    }
}
