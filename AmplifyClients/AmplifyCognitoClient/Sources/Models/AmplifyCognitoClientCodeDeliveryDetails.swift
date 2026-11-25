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
public struct AmplifyCognitoClientCodeDeliveryDetails {

    /// Destination to which the code was delivered.
    public let destination: AmplifyCognitoClientDeliveryDestination

    /// Attribute that is confirmed or verified.
    public let attributeKey: AmplifyCognitoClientUserAttributeKey?

    public init(
        destination: AmplifyCognitoClientDeliveryDestination,
        attributeKey: AmplifyCognitoClientUserAttributeKey? = nil
    ) {
        self.destination = destination
        self.attributeKey = attributeKey
    }
}

extension AmplifyCognitoClientCodeDeliveryDetails: Equatable {}

extension AmplifyCognitoClientCodeDeliveryDetails: Sendable {}
