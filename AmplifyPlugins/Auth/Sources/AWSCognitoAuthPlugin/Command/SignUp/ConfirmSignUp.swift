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

    let username: String
    let confirmationCode: String

    init(username: String,
         confirmationCode: String) {
        self.username = username
        self.confirmationCode = confirmationCode
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

        let input = ConfirmSignUpInput(username: username,
                                       confirmationCode: confirmationCode)
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
                // error is ConfirmSignUpOutputError
                // https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_ConfirmSignUp.html#API_ConfirmSignUp_Errors

                // TODO: change to SignUpError once the PR with AuthErrorConvertible is merged to dev-preview
                let authError = AuthenticationError.service(message: error.localizedDescription)
                event = SignUpEvent(
                    id: UUID().uuidString,
                    eventType: .throwAuthError(authError)
                )
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
