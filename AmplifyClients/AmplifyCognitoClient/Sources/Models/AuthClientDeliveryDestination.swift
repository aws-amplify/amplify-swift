//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Destination to where an item (e.g., confirmation code) was delivered.
///
/// Mirrors Amplify core's `DeliveryDestination` case for case.
///
/// May gain cases in a minor release: include `@unknown default` when you switch over it.
@_spi(AmplifyExperimental)
public enum AuthClientDeliveryDestination {

    /// Email destination with optional associated value containing the email info
    case email(String?)

    /// Phone destination with optional associated value containing the phone number info
    case phone(String?)

    /// SMS destination with optional associated value containing the number info
    case sms(String?)

    /// Unknown destination with optional associated value destination detail
    case unknown(String?)
}

extension AuthClientDeliveryDestination: Equatable {}

extension AuthClientDeliveryDestination: Sendable {}
