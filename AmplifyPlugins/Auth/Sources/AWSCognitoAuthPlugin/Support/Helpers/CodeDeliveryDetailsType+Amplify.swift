//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSCognitoIdentityProvider
import Foundation
import InternalAWSCognitoAuth

// The plugin half of `Service/Helpers/SignUpOutputResponse+Helper.swift`: Amplify's delivery details for
// the tasks and operation helpers that return them. Both go through the engine half and the
// `Support/EngineBridge/` converters, so the SDK mapping exists once.

extension CognitoIdentityProviderClientTypes.CodeDeliveryDetailsType {

    func toDeliveryDestination() -> DeliveryDestination {
        DeliveryDestination(toEngineDeliveryDestination())
    }

    func toAuthCodeDeliveryDetails() -> AuthCodeDeliveryDetails {
        AuthCodeDeliveryDetails(toEngineCodeDeliveryDetails())
    }

}
