//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// Docs:
// https://awslabs.github.io/aws-sdk-swift/reference/0.x/AWSCognitoIdentityProvider/CognitoIdentityProviderClientProtocol
// https://docs.aws.amazon.com/cognito/latest/developerguide/signing-up-users-in-your-app.html

// SignUp
// https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_SignUp.html

// ConfirmSignUp
// https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_ConfirmSignUp.html

import Foundation
import AWSCognitoIdentityProvider

struct SignUpEvent: StateMachineEvent {
    var data: Any?

    enum EventType: Equatable {
        case initiateSignUp(SignUpEventData)
        case confirmSignUp(ConfirmSignUpEventData)
        case initiateSignUpSuccess(username: String, signUpResponse: SignUpOutputResponse)
        case initiateSignUpFailure(error: SignUpError)
        case confirmSignUpSuccess(confirmSignupResponse: ConfirmSignUpOutputResponse)
        case confirmSignUpFailure(error: SignUpError)
        case throwAuthError(AuthenticationError)
    }

    let id: String
    let eventType: EventType
    let time: Date?

    var type: String {
        switch eventType {
        case .initiateSignUp:
            return "SignUpEvent.initiateSignUp"
        case .confirmSignUp:
            return "SignUpEvent.confirmSignUp"
        case .initiateSignUpSuccess:
            return "SignUpEvent.initiateSignUpSuccess"
        case .initiateSignUpFailure:
            return "SignUpEvent.initiateSignUpFailure"
        case .confirmSignUpSuccess:
            return "SignUpEvent.confirmSignUpSuccess"
        case .confirmSignUpFailure:
            return "SignUpEvent.initiatConfirmSignUpFailure"
        case .throwAuthError:
            return "SignUpEvent.throwAuthError"
        }
    }

    init(
        id: String = UUID().uuidString,
        eventType: EventType,
        time: Date? = nil
    ) {
        self.id = id
        self.eventType = eventType
        self.time = time
    }
}
