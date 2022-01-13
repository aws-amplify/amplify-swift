//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import hierarchical_state_machine_swift
import AWSCognitoIdentityProvider
import Amplify

struct InitiateSignUp: Command {
    let identifier = "InitiateSignUp"

    let username: String
    let password: String

    init(username: String, password: String) {
        self.username = username
        self.password = password
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

        let input = SignUpInput(username: username, password: password)
        timer.note("### Starting signUp")
        client.signUp(input: input) { result in
            timer.note("### signUp response received")
            let event: SignUpEvent
            switch result {
            case .success(let response):
                event = SignUpEvent(id: UUID().uuidString,
                                    eventType: .initiateSignUpSuccess(username: username, signUpResponse: response),
                                    time: Date())
            case .failure(let error):
                // error is SignUpOutputError
                // https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_SignUp.html#API_SignUp_Errors

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

extension SignUpInput {
    init(username: String, password: String) {
        self.init(password: password, username: username)
    }
}
