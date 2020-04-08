//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AuthCodeDeliveryDetails {

    public let destination: String

    public let deliveryMedium: DeliveryMedium

    public let attributeName: String

    public init(destination: String,
                 deliveryMedium: DeliveryMedium,
                 attributeName: String) {
        self.destination = destination
        self.deliveryMedium = deliveryMedium
        self.attributeName = attributeName
    }

}

//TODO: Should we move this under AuthCodeDeliveryDetails extension?
public enum DeliveryMedium {
    case sms
    case email
    case phoneNumber
    case custom(String)
}
