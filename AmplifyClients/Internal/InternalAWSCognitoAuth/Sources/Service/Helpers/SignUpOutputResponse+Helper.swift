//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSCognitoIdentityProvider
import Foundation

// The engine half: SDK values to engine values. The plugin half, which builds Amplify's delivery
// details, is `Support/Helpers/CodeDeliveryDetailsType+Amplify.swift`.

package extension SignUpOutput {

    var authResponse: EngineSignUpResult {
        if userConfirmed {
            return .init(.done, userID: userSub)
        }
        return EngineSignUpResult(
            .confirmUser(
                codeDeliveryDetails?.toEngineCodeDeliveryDetails(),
                nil,
                userSub
            ),
            userID: userSub
        )
    }
}

package extension CognitoIdentityProviderClientTypes.CodeDeliveryDetailsType {

    func toEngineDeliveryDestination() -> EngineDeliveryDestination {
        switch deliveryMedium {
        case .email:
            return EngineDeliveryDestination.email(destination)
        case .sms:
            return EngineDeliveryDestination.sms(destination)
        default:
            return EngineDeliveryDestination.unknown(destination)
        }
    }

    /// The attribute stays the Cognito wire name; the plugin builds `AuthUserAttributeKey` from it.
    func toEngineCodeDeliveryDetails() -> EngineCodeDeliveryDetails {
        let destination = toEngineDeliveryDestination()
        guard let attributeToVerify = attributeName else {
            return  EngineCodeDeliveryDetails(destination: destination)
        }
        return  EngineCodeDeliveryDetails(
            destination: destination,
            attributeKey: attributeToVerify
        )
    }

}
