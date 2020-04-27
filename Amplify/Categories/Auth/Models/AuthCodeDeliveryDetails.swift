//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AuthCodeDeliveryDetails {

    /// Destination to which the code was delivered.
    public let destination: DeliveryDestination

    /// Attribute that is confirmed or verified.
    public let attributeName: String?

    public init(destination: DeliveryDestination,
                 attributeName: String? = nil) {
        self.destination = destination
        self.attributeName = attributeName
    }
}
