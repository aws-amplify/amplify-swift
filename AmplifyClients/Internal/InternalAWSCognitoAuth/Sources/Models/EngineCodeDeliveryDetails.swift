//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The engine's copy of `Amplify.AuthCodeDeliveryDetails`.
///
/// The attribute is the Cognito wire name (`"email"`, `"custom:x"`, ...), not Amplify's
/// `AuthUserAttributeKey`, which stays plugin-side. The member keeps
/// the public name, `attributeKey`, so a printed value reads the same once the log-transcript golden's
/// normaliser maps the type names back; only its type is the wire `String`. The plugin
/// builds the key with `AuthUserAttributeKey(rawValue:)`, as it did before the fork, in
/// `AWSCognitoAuthPlugin/Support/EngineBridge/AuthCodeDeliveryDetails+Engine.swift`.
package struct EngineCodeDeliveryDetails {

    /// Destination to which the code was delivered.
    package let destination: EngineDeliveryDestination

    /// The Cognito name of the attribute the code was sent to verify, if any.
    package let attributeKey: String?

    package init(
        destination: EngineDeliveryDestination,
        attributeKey: String? = nil
    ) {
        self.destination = destination
        self.attributeKey = attributeKey
    }
}

extension EngineCodeDeliveryDetails: Equatable { }

extension EngineCodeDeliveryDetails: Sendable { }

/// The engine's copy of `Amplify.DeliveryDestination`: the same cases, with the same unlabeled
/// `String?` payloads.
package enum EngineDeliveryDestination {

    /// Code was sent via email
    case email(String?)

    /// Code was sent via a phone
    case phone(String?)

    /// Code was sent via sms
    case sms(String?)

    /// Code was sent via some other channel
    case unknown(String?)
}

extension EngineDeliveryDestination: Equatable { }

extension EngineDeliveryDestination: Sendable { }
