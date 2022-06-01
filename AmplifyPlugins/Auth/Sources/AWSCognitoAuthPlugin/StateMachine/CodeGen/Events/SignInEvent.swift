//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSCognitoIdentityProvider
import Amplify

struct SignInEvent: StateMachineEvent {
    

    enum EventType: Equatable {

        case receivedSMSChallenge(RespondToAuthChallenge)

        case verifySMSChallenge(String)

    }

    let id: String
    let eventType: EventType
    let time: Date?

    var type: String {
        switch eventType {
        case .receivedSMSChallenge: return "SignInEvent.respondWithSMSChallenge"
        case .verifySMSChallenge: return "SignInEvent.verifySMSChallenge"
        }
    }

    init(id: String = UUID().uuidString,
         eventType: EventType,
         time: Date? = nil) {
        self.id = id
        self.eventType = eventType
        self.time = time
    }
}

struct RespondToAuthChallenge: Equatable {

    let challenge: CognitoIdentityProviderClientTypes.ChallengeNameType
    let username: String
    let session: String
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

}
