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

import hierarchical_state_machine_swift
import AWSCognitoIdentityProvider

public struct SignUpEvent: StateMachineEvent {
    public var data: Any?

    public enum EventType: Equatable {
        case initiateSignUp(username: String, password: String)
        case confirmSignUp(username: String, confirmationCode: String)
        case initiateSignUpSuccess(username: String, signUpResponse: SignUpOutputResponse)
        case initiateSignUpFailure(signUpResponse: SignUpOutputResponse)
        case confirmSignUpSuccess(confirmSignupResponse: ConfirmSignUpOutputResponse)
        case confirmSignUpFailure(confirmSignupResponse: ConfirmSignUpOutputResponse)
        case throwAuthError(AuthenticationError)
    }

    public let id: String
    public let eventType: EventType
    public let time: Date?

    public var type: String {
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

    public init(
        id: String,
        eventType: EventType,
        time: Date? = nil
    ) {
        self.id = id
        self.eventType = eventType
        self.time = time
    }
}
