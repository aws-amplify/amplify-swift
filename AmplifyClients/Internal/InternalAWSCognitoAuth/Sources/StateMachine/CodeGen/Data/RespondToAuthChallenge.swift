//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation

package struct RespondToAuthChallenge: Equatable {

    package let challenge: CognitoIdentityProviderClientTypes.ChallengeNameType

    package let availableChallenges: [CognitoIdentityProviderClientTypes.ChallengeNameType]

    package let username: String

    package let session: String?

    package let parameters: [String: String]?

    package var inputUsername: String?

    /// The memberwise initializer, as the compiler synthesized it before the move: the optional `var`
    /// defaults to `nil`.
    package init(
        challenge: CognitoIdentityProviderClientTypes.ChallengeNameType,
        availableChallenges: [CognitoIdentityProviderClientTypes.ChallengeNameType],
        username: String,
        session: String?,
        parameters: [String: String]?,
        inputUsername: String? = nil
    ) {
        self.challenge = challenge
        self.availableChallenges = availableChallenges
        self.username = username
        self.session = session
        self.parameters = parameters
        self.inputUsername = inputUsername
    }
}

package extension RespondToAuthChallenge {

    var codeDeliveryDetails: EngineCodeDeliveryDetails {
        guard let parameters,
              let medium = parameters["CODE_DELIVERY_DELIVERY_MEDIUM"] else {
            return EngineCodeDeliveryDetails(
                destination: .unknown(nil),
                attributeKey: nil
            )
        }

        var deliveryDestination = EngineDeliveryDestination.unknown(nil)
        let destination = parameters["CODE_DELIVERY_DESTINATION"]
        if medium == "SMS" {
            deliveryDestination = .sms(destination)
        } else if medium == "EMAIL" {
            deliveryDestination = .email(destination)
        }
        return EngineCodeDeliveryDetails(
            destination: deliveryDestination,
            attributeKey: nil
        )
    }

    /// The MFA types offered for selection. An unsupported one is logged through `logger`, the caller's.
    func getAllowedMFATypesForSelection(logger: any EngineScopedLogger) -> Set<EngineMFAType> {
        return getMFATypes(forKey: "MFAS_CAN_CHOOSE", logger: logger)
    }

    /// The MFA types offered for setup. An unsupported one is logged through `logger`, the caller's.
    func getAllowedMFATypesForSetup(logger: any EngineScopedLogger) -> Set<EngineMFAType> {
        return getMFATypes(forKey: "MFAS_CAN_SETUP", logger: logger)
    }

    var getAllowedAuthFactorsForSelection: Set<EngineAuthFactorType> {
        return Set(availableChallenges.compactMap { $0.authFactor })
    }

    /// Helper method to extract MFA types from parameters
    private func getMFATypes(forKey key: String, logger: any EngineScopedLogger) -> Set<EngineMFAType> {
        guard let mfaTypeParameters = parameters?[key],
              let mfaTypesArray = try? JSONDecoder().decode(
                  [String].self,
                  from: Data(mfaTypeParameters.utf8)
              )
        else { return .init() }

        let mfaTypes = mfaTypesArray.compactMap { EngineMFAType(rawValue: $0, logger: logger) }
        return Set(mfaTypes)
    }

    var debugDictionary: [String: Any] {
        return [
            "challenge": challenge,
            "username": username.maskedForLog()
        ]
    }

    func getChallengeKey() throws -> String {
        switch challenge {
        case .customChallenge, .selectMfaType, .selectChallenge: return "ANSWER"
        case .smsMfa: return "SMS_MFA_CODE"
        case .softwareTokenMfa: return "SOFTWARE_TOKEN_MFA_CODE"
        case .newPasswordRequired: return "NEW_PASSWORD"
        case .emailOtp: return "EMAIL_OTP_CODE"
        // At the moment of writing this code, `mfaSetup` only supports EMAIL.
        // TOTP is not part of it because, it follows a completely different setup path
        case .mfaSetup: return "EMAIL"
        case .smsOtp: return "SMS_OTP_CODE"
        default:
            let message = "Unsupported challenge type for response key generation \(challenge)"
            let error = SignInError.unknown(message: message)
            throw error
        }
    }

}

extension RespondToAuthChallenge: Codable { }
