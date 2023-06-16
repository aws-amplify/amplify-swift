//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSCognitoIdentityProvider

struct RespondToAuthChallenge: Equatable {

    let challenge: CognitoIdentityProviderClientTypes.ChallengeNameType

    let username: String

    let session: String?

    let parameters: [String: String]?

}

extension RespondToAuthChallenge {

    var codeDeliveryDetails: AuthCodeDeliveryDetails {
        guard let parameters = parameters,
              let medium = parameters["CODE_DELIVERY_DELIVERY_MEDIUM"] else {
            return AuthCodeDeliveryDetails(destination: .unknown(nil),
                                           attributeKey: nil)
        }

        var deliveryDestination = DeliveryDestination.unknown(nil)
        let destination = parameters["CODE_DELIVERY_DESTINATION"]
        if medium == "SMS" {
            deliveryDestination = .sms(destination)
        }
        return AuthCodeDeliveryDetails(destination: deliveryDestination,
                                       attributeKey: nil)
    }

    var debugDictionary: [String: Any] {
        return ["challenge": challenge,
                "username": username.masked()]
    }

    func getChallengeKey() throws -> String {
        switch challenge {
        case .customChallenge: return "ANSWER"
        case .smsMfa: return "SMS_MFA_CODE"
        case .softwareTokenMfa: return "SOFTWARE_TOKEN_MFA_CODE"
        case .newPasswordRequired: return "NEW_PASSWORD"
        case .selectMfaType: return "SELECT_MFA_TYPE"
        default:
            let message = "Unsupported challenge response \(challenge)"
            let error = SignInError.unknown(message: message)
            throw error
        }
    }

}

extension RespondToAuthChallenge: Codable { }
