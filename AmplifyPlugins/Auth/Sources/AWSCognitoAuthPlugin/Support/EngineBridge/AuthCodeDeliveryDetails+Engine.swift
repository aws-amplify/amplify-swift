//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import InternalAWSCognitoAuth

// Conversions between `Amplify.AuthCodeDeliveryDetails` / `DeliveryDestination` and the engine's
// `EngineCodeDeliveryDetails` / `EngineDeliveryDestination`. Destinations go case to case, with the payload
// unchanged.
//
// The attribute is the one place where the two sides differ in type: the engine holds the Cognito wire
// name, the public type an `AuthUserAttributeKey`.
// - Engine → plugin builds the key with `AuthUserAttributeKey(rawValue:)`, which is what the plugin did
//   with the service's `attributeName` before the fork. `rawValue` of that key gives the name back, for
//   every string, so engine → plugin → engine is the identity.
// - Plugin → engine takes the key's `rawValue`. That is the identity for every key the plugin builds from
//   a wire name. Only a hand-built key whose name is a known attribute (`.unknown("email")`) comes back as
//   the canonical key (`.email`).

extension EngineCodeDeliveryDetails {

    init(_ details: AuthCodeDeliveryDetails) {
        self.init(
            destination: EngineDeliveryDestination(details.destination),
            attributeKey: details.attributeKey?.rawValue
        )
    }
}

extension AuthCodeDeliveryDetails {

    init(_ details: EngineCodeDeliveryDetails) {
        self.init(
            destination: DeliveryDestination(details.destination),
            attributeKey: details.attributeKey.map { AuthUserAttributeKey(rawValue: $0) }
        )
    }
}

extension EngineDeliveryDestination {

    init(_ destination: DeliveryDestination) {
        switch destination {
        case .email(let value): self = .email(value)
        case .phone(let value): self = .phone(value)
        case .sms(let value): self = .sms(value)
        case .unknown(let value): self = .unknown(value)
        }
    }
}

extension DeliveryDestination {

    init(_ destination: EngineDeliveryDestination) {
        switch destination {
        case .email(let value): self = .email(value)
        case .phone(let value): self = .phone(value)
        case .sms(let value): self = .sms(value)
        case .unknown(let value): self = .unknown(value)
        }
    }
}
