//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCognitoIdentityProvider
import CryptoKit

struct ConfirmSignUp: Action {
    let identifier = "ConfirmSignUp"

    let confirmSignUpEventData: ConfirmSignUpEventData

    init(confirmSignUpEventData: ConfirmSignUpEventData) {
        self.confirmSignUpEventData = confirmSignUpEventData
    }

    func execute(
        withDispatcher dispatcher: EventDispatcher,
        environment: Environment
    ) {

        logVerbose("\(#fileID) Starting execution", environment: environment)
        guard let environment = environment as? UserPoolEnvironment else {
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

        let input = ConfirmSignUpInput(username: confirmSignUpEventData.username,
                                       confirmationCode: confirmSignUpEventData.confirmationCode,
                                       environment: environment)
        logVerbose("\(#fileID) Starting ConfirmSignUp", environment: environment)
        Task {
            let event: SignUpEvent
            do {
                let response = try await client.confirmSignUp(input: input)
                logVerbose("\(#fileID) ConfirmSignUp received", environment: environment)
                event = SignUpEvent(id: UUID().uuidString,
                                    eventType: .confirmSignUpSuccess(confirmSignupResponse: response),
                                    time: Date())
            } catch {
                let error = SignUpError.service(error: error)
                event = SignUpEvent(eventType: .confirmSignUpFailure(error: error))
            }
            logVerbose("\(#fileID) Sending event \(event.type)", environment: environment)
            dispatcher.send(event)
        }
    }
}
