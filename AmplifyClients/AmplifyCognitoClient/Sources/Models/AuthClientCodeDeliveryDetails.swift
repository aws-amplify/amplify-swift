//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Details on where a code has been delivered.
///
/// Mirrors Amplify core's `AuthCodeDeliveryDetails`.
@_spi(AmplifyExperimental)
public struct AuthClientCodeDeliveryDetails {

    /// Destination to which the code was delivered.
    public let destination: AuthClientDeliveryDestination

    /// Attribute that is confirmed or verified.
    public let attributeKey: AuthClientUserAttributeKey?

    public init(
        destination: AuthClientDeliveryDestination,
        attributeKey: AuthClientUserAttributeKey? = nil
    ) {
        self.destination = destination
        self.attributeKey = attributeKey
    }
}

extension AuthClientCodeDeliveryDetails: Equatable {}

extension AuthClientCodeDeliveryDetails: Sendable {}
