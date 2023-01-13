//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

public extension AnalyticsUserProfile {
    /// Defines constants used specificaly for AWS Pinpoint
    enum AWSPinpoint {
        public enum Endpoint {
            /// Add this prefix to a property key to mark it as an Endpoint's Custom attribute.
            public static let customAttributePrefix = "endpointCustomAttribute::"

            /// Add this prefix to a property key to mark it as an Endpoint's User attribute.
            public static let userAttributePrefix = "endpointUserAttribute::"
        }
    }

    /// Adds a property to the Endpoint's Custom Attributes.
    ///
    /// The given key will be prefixed with `AnalyticsUserProfile.AWSPinpoint.endpointPrefix` in order to identify it.
    ///
    /// - Parameter property: The property value
    /// - Parameter key: The property key
    mutating func addPinpointEndpointCustomProperty(_ property: AnalyticsPropertyValue,
                                                    forKey key: String) {
        addProperty(
            property,
            forKey: key.prefixed(AnalyticsUserProfile.AWSPinpoint.Endpoint.customAttributePrefix)
        )
    }

    /// Adds a property to the Endpoint's User Attributes.
    ///
    /// The given key will be prefixed with `AnalyticsUserProfile.AWSPinpoint.userPrefix` in order to identify it.
    ///
    /// - Parameter property: The property value
    /// - Parameter key: The property key
    mutating func addPinpointEndpointUserProperty(_ property: AnalyticsPropertyValue,
                                                  forKey key: String) {
        addProperty(
            property,
            forKey: key.prefixed(AnalyticsUserProfile.AWSPinpoint.Endpoint.userAttributePrefix)
        )
    }

    /// Adds properties to the Endpoint's Custom Attributes.
    ///
    /// All keys will be prefixed with `AnalyticsUserProfile.AWSPinpoint.endpointPrefix` in order to identify them.
    ///
    /// - Parameter properties: A dictionary containing the properties keys and values
    mutating func addPinpointEndpointProperties(_ properties: AnalyticsProperties) {
        for (key, value) in properties {
            addPinpointEndpointCustomProperty(value, forKey: key)
        }
    }

    /// Adds properties to the Endpoint's User Attributes.
    /// 
    /// All keys will be prefixed with `AnalyticsUserProfile.AWSPinpoint.userPrefix` in order to identify them.
    ///
    /// - Parameter properties: A dictionary containing the properties keys and values
    mutating func addPinpointUserProperties(_ properties: AnalyticsProperties) {
        for (key, value) in properties {
            addPinpointEndpointUserProperty(value, forKey: key)
        }
    }

    private mutating func addProperty(_ property: AnalyticsPropertyValue,
                                      forKey key: String) {
        var properties = self.properties ?? [:]
        properties[key] = property
        self.properties = properties
    }

    /// The properties that are mapped to the Endpoint's Custom Attributes . The keys in this dictionary do not have any generated prefix.
    var endpointCustomProperties: AnalyticsProperties? {
        guard let properties = properties else {
            return nil
        }

        var customProperties: AnalyticsProperties = [:]
        for (key, value) in properties {
            if key.hasPrefix(AWSPinpoint.Endpoint.customAttributePrefix) {
                let newKey = String(key.dropFirst(AWSPinpoint.Endpoint.customAttributePrefix.count))
                customProperties[newKey] = value
            } else if !key.hasPrefix(AWSPinpoint.Endpoint.userAttributePrefix) {
                // Unless the key is explicitly prefixed as a userAttribute,
                // we should consider it a custom property as is.
                customProperties[key] = value
            }
        }

        return customProperties
    }

    /// The properties that are mapped to the Endpoint's User Attributes. The keys in this dictionary do not have any generated prefix.
    var endpointUserProperties: AnalyticsProperties? {
        guard let properties = properties else {
            return nil
        }

        var userProperties: AnalyticsProperties = [:]
        for (key, value) in properties where key.hasPrefix(AWSPinpoint.Endpoint.userAttributePrefix) {
            let newKey = String(key.dropFirst(AWSPinpoint.Endpoint.userAttributePrefix.count))
            userProperties[newKey] = value
        }

        return userProperties
    }
}

private extension String {
    func prefixed(_ prefix: String) -> String {
        guard !hasPrefix(prefix) else {
            return self
        }
        return "\(prefix)\(self)"
    }
}
