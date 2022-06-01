//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@testable import AWSCognitoAuthPlugin
@testable import AWSPluginsTestCommon
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
        eventType: .initiateSignUp(SignUpEventData()), time: nil
    )

    static let confirmSignUpEvent = SignUpEvent(
        id: "confirmSignUp",
        eventType: .confirmSignUp(ConfirmSignUpEventData()), time: nil
    )


    static let initiateSignUpSuccessEvent = SignUpEvent(
        id: "initiateSignUpSuccess",
        eventType: .initiateSignUpSuccess(username: "", signUpResponse: SignUpOutputResponse()), time: nil
    )

    static let initiateSignUpFailureEvent = SignUpEvent(
        id: "initiateSignUpFailure",
        eventType: .initiateSignUpFailure(error: SignUpError.invalidUsername(message: "")), time: nil
    )

    static let confirmSignUpSuccessEvent = SignUpEvent(
        id: "confirmSignUpSuccess",
        eventType: .confirmSignUpSuccess(
            confirmSignupResponse: try! ConfirmSignUpOutputResponse(httpResponse: MockHttpResponse.ok)
        ),
        time: nil
    )

    static let confirmSignUpFailureEvent = SignUpEvent(
        id: "confirmSignUpFailure",
        eventType: .confirmSignUpFailure(error: SignUpError.invalidConfirmationCode(message: "")), time: nil
    )

}
