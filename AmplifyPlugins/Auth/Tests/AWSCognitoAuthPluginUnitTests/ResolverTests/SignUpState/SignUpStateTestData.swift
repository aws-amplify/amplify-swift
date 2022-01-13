//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@testable import AWSCognitoAuthPlugin
import AWSCognitoIdentityProvider

extension SignUpEvent {

    static let allStates: [SignUpEvent] = [
        initiateSignUpEvent,
        confirmSignUpEvent,
        initiateSignUpSuccessEvent,
        initiateSignUpFailureEvent,
        confirmSignUpSuccessEvent,
        confirmSignUpFailureEvent
    ]

    static let initiateSignUpEvent = SignUpEvent(
        id: "initiateSignUp",
        eventType: .initiateSignUp(username: "", password: ""), time: nil
    )

    static let confirmSignUpEvent = SignUpEvent(
        id: "confirmSignUp",
        eventType: .confirmSignUp(username: "", confirmationCode: ""), time: nil
    )


    static let initiateSignUpSuccessEvent = SignUpEvent(
        id: "initiateSignUpSuccess",
        eventType: .initiateSignUpSuccess(username: "", signUpResponse: SignUpOutputResponse()), time: nil
    )

    static let initiateSignUpFailureEvent = SignUpEvent(
        id: "initiateSignUpFailure",
        eventType: .initiateSignUpFailure(signUpResponse: SignUpOutputResponse()), time: nil
    )

    static let confirmSignUpSuccessEvent = SignUpEvent(
        id: "confirmSignUpSuccess",
        eventType: .confirmSignUpSuccess(confirmSignupResponse: ConfirmSignUpOutputResponse()), time: nil
    )

    static let confirmSignUpFailureEvent = SignUpEvent(
        id: "confirmSignUpFailure",
        eventType: .confirmSignUpFailure(confirmSignupResponse: ConfirmSignUpOutputResponse()), time: nil
    )

}
