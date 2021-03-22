//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
#if COCOAPODS
import AWSMobileClient
#else
import AWSMobileClientXCF
#endif

extension UserCodeDeliveryDetails {

    func toDeliveryDestination() -> DeliveryDestination {
        switch deliveryMedium {
        case .email:
            return DeliveryDestination.email(destination)
        case .sms:
            return DeliveryDestination.sms(destination)
        case .unknown:
            return DeliveryDestination.unknown(destination)
        }
    }

    func toAuthCodeDeliveryDetails() -> AuthCodeDeliveryDetails {
        let destination = toDeliveryDestination()
        guard let attributeToVerify = attributeName else {
            return  AuthCodeDeliveryDetails(destination: destination)
        }
        return  AuthCodeDeliveryDetails(destination: destination,
                                        attributeKey: AuthUserAttributeKey(rawValue: attributeToVerify))
    }

}
