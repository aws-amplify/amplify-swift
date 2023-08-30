//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSCognitoIdentityProvider

extension SignUpOutputResponse {

    var authResponse: AuthSignUpResult {
        if self.userConfirmed {
            return .init(.done)
        }
        return AuthSignUpResult(
            .confirmUser(
                codeDeliveryDetails?.toAuthCodeDeliveryDetails(),
                nil,
                userSub
            )
        )
    }
}

extension CognitoIdentityProviderClientTypes.CodeDeliveryDetailsType {

    func toDeliveryDestination() -> DeliveryDestination {
        switch deliveryMedium {
        case .email:
            return DeliveryDestination.email(destination)
        case .sms:
            return DeliveryDestination.sms(destination)
        default:
            return DeliveryDestination.unknown(destination)
        }
    }

    func toAuthCodeDeliveryDetails() -> AuthCodeDeliveryDetails {
        let destination = toDeliveryDestination()
        guard let attributeToVerify = attributeName else {
            return  AuthCodeDeliveryDetails(destination: destination)
        }
        return  AuthCodeDeliveryDetails(
            destination: destination,
            attributeKey: AuthUserAttributeKey(rawValue: attributeToVerify))
    }

}
