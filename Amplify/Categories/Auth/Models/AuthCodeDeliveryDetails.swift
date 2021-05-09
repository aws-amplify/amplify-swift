//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// <#Description#>
public typealias AdditionalInfo = [String: String]

/// <#Description#>
public struct AuthCodeDeliveryDetails {

    /// Destination to which the code was delivered.
    public let destination: DeliveryDestination

    /// Attribute that is confirmed or verified.
    public let attributeKey: AuthUserAttributeKey?

    /// <#Description#>
    /// - Parameters:
    ///   - destination: <#destination description#>
    ///   - attributeKey: <#attributeKey description#>
    public init(destination: DeliveryDestination,
                attributeKey: AuthUserAttributeKey? = nil) {
        self.destination = destination
        self.attributeKey = attributeKey
    }
}
