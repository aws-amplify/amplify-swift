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

    var getAllowedMFATypesForSelection: Set<MFAType> {
        return getMFATypes(forKey: "MFAS_CAN_CHOOSE")
    }

    var getAllowedMFATypesForSetup: Set<MFAType> {
        return getMFATypes(forKey: "MFAS_CAN_SETUP")
    }

    /// Helper method to extract MFA types from parameters
    private func getMFATypes(forKey key: String) -> Set<MFAType> {
        var mfaTypes = Set<MFAType>()
        guard let mfaTypeParametersData = parameters?[key]?.data(using: .utf8),
              let mfaTypesArray = try? JSONDecoder().decode(
                [String].self, from: mfaTypeParametersData) else {
            return mfaTypes
        }

        for mfaTypeValue in mfaTypesArray {
            if let mfaType = MFAType(rawValue: String(mfaTypeValue)) {
                mfaTypes.insert(mfaType)
            }
        }

        return mfaTypes
    }

    var debugDictionary: [String: Any] {
        return ["challenge": challenge,
                "username": username.masked()]
    }

    func getChallengeKey() throws -> String {
        switch challenge {
        case .customChallenge, .selectMfaType: return "ANSWER"
        case .smsMfa: return "SMS_MFA_CODE"
        case .softwareTokenMfa: return "SOFTWARE_TOKEN_MFA_CODE"
        case .newPasswordRequired: return "NEW_PASSWORD"
        default:
            let message = "Unsupported challenge response \(challenge)"
            let error = SignInError.unknown(message: message)
            throw error
        }
    }

}

extension RespondToAuthChallenge: Codable { }
