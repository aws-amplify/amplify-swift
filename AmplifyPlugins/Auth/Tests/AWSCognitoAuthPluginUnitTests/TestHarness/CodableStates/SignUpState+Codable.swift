//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSCognitoAuthPlugin
import Foundation
import Amplify

extension SignUpState: Codable {
    
    enum CodingKeys: String, CodingKey {
        case type
        case SignUpEventData
        case AuthSignUpResult
        case SignUpError
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let type = try values.decode(String.self, forKey: .type)
        if type == "SignUpState.notStarted" {
            self = .notStarted
        } else if type == "SignUpState.initiatingSignUp" {
            let eventData = try values.decode(SignUpEventData.self, forKey: .SignUpEventData)
            self = .initiatingSignUp(eventData)
        }  else if type == "SignUpState.awaitingUserConfirmation" {
            let eventData = try values.decode(SignUpEventData.self, forKey: .SignUpEventData)
            let result = try values.decode(AuthSignUpResult.self, forKey: .AuthSignUpResult)
            self = .awaitingUserConfirmation(eventData, result)
        }  else if type == "SignUpState.confirmingSignUp" {
            let eventData = try values.decode(SignUpEventData.self, forKey: .SignUpEventData)
            self = .confirmingSignUp(eventData)
        }  else if type == "SignUpState.signedUp" {
            let eventData = try values.decode(SignUpEventData.self, forKey: .SignUpEventData)
            let result = try values.decode(AuthSignUpResult.self, forKey: .AuthSignUpResult)
            self = .signedUp(eventData, result)
        } else if type == "SignUpState.error" {
            let eventError = try values.decode(SignUpError.self, forKey: .SignUpError)
            self = .error(eventError)
        } else {
            fatalError("Decoding not supported")
        }
    }

    public func encode(to encoder: Encoder) throws {
        fatalError("Encoding not supported")
    }
    
}
