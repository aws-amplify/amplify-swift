//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCognitoIdentityProvider

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

        let timer = LoggingTimer(identifier).start("### Starting execution")
        guard let environment = environment as? UserPoolEnvironment else {
            let authError = AuthenticationError.configuration(message: "Environment configured incorrectly")
            let event = SignUpEvent(
                id: UUID().uuidString,
                eventType: .throwAuthError(authError)
            )
            dispatcher.send(event)
            return
        }

        let client: CognitoUserPoolBehavior
        do {
            client = try createIdentityProviderClient(key: confirmSignUpEventData.key, environment: environment)
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
                                       confirmationCode:  confirmSignUpEventData.confirmationCode)
        timer.note("### Starting confirmSignUp")
        client.confirmSignUp(input: input) { result in
            timer.note("### confirmSignUp response received")
            let event: SignUpEvent
            switch result {
            case .success(let response):
                event = SignUpEvent(id: UUID().uuidString,
                                    eventType: .confirmSignUpSuccess(confirmSignupResponse: response),
                                    time: Date())
            case .failure(let error):
                let error = SignUpError.service(error: error)
                event = SignUpEvent(eventType: .confirmSignUpFailure(error: error))
            }
            dispatcher.send(event)
            timer.stop("### sending SignUpEvent.initiateSignUpResponseReceived")
        }
    }
}

extension ConfirmSignUpInput {
    init(username: String, confirmationCode: String) {
        self.init(
            confirmationCode: confirmationCode,
            username: username)
    }
}
