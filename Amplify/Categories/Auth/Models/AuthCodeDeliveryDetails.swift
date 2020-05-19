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
    public let attributeKey: AuthUserAttributeKey?

    public init(destination: DeliveryDestination,
                attributeKey: AuthUserAttributeKey? = nil) {
        self.destination = destination
        self.attributeKey = attributeKey
    }
}
