//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCognitoIdentityProvider
import Amplify

typealias ConfirmationCode = String
typealias ForceAliasCreation = Bool
struct SignUpEvent: StateMachineEvent {
    var id: String
    var time: Date?
    let eventType: EventType
    
    enum EventType {
        case initiateSignUp(SignUpEventData, Password?, [AuthUserAttribute]?)
        case initiateSignUpComplete(SignUpEventData, AuthSignUpResult)
        case confirmSignUp(SignUpEventData, ConfirmationCode, ForceAliasCreation?)
        case signedUp(SignUpEventData, AuthSignUpResult)
        case throwAuthError(SignUpError)
    }
    
    init(id: String = UUID().uuidString,
         eventType: EventType,
         time: Date? = nil) {
        self.id = id
        self.eventType = eventType
        self.time = time
    }
    
    var type: String {
        switch eventType {
        case .initiateSignUp: return "SignUpEvent.initiateSignUp"
        case .initiateSignUpComplete: return "SignUpEvent.initiateSignUpComplete"
        case .confirmSignUp: return "SignUpEvent.confirmSignUp"
        case .signedUp: return "SignUpEvent.signedUp"
        case .throwAuthError: return "SignUpEvent.throwAuthError"
        }
    }
    
}
