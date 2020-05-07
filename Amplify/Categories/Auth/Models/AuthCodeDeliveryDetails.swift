//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public typealias AdditionalInfo = [String: String]

public struct AuthCodeDeliveryDetails {

    /// Destination to which the code was delivered.
    public let destination: DeliveryDestination

    /// Attribute that is confirmed or verified.
    // TODO: Change to attributeType #172336364
    public let attributeName: String?

    public init(destination: DeliveryDestination,
                attributeName: String? = nil) {
        self.destination = destination
        self.attributeName = attributeName
    }
}
