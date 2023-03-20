//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// A Pinpoint-specific implementation of `UserProfile`
public struct PinpointUserProfile: UserProfile {
    public var name: String?

    public var email: String?

    public var plan: String?

    public var location: UserProfileLocation?

    /// Custom properties, which are mapped to the endpoint's `attributes` and `metrics`.
    ///
    /// Each mapping is determined by the property value type.
    ///
    /// - **Attributes**: Values of type `String`, `Bool` or `Array<String>`. For example:
    /// ```
    /// var pinpointUserProfile = PinpointUserProfile()
    /// pinpointUserProfile.customProperties = [
    ///     "stringAttribute": "single",
    ///     "stringAttributes": ["one", "two"],
    ///     "boolAttribute": true
    /// ]
    /// ```
    ///
    /// - **Metrics**: Values of type `Int` or `Double`. For example:
    /// ```
    /// var pinpointUserProfile = PinpointUserProfile()
    /// pinpointUserProfile.customProperties = [
    ///     "intMetric": 1,
    ///     "doubleMetric": 2.0
    /// ]
    /// ```
    public var customProperties: [String: UserProfilePropertyValue]?

    /// User attributes, which are mapped to the endpoint's `user attributes`.
    public var userAttributes: [String: [String]]?

    /// Whether the user has opted out of receiving messages and push notifications from Pinpoint.
    public var optedOutOfMessages: Bool?

    /// Initializer
    /// - Parameters:
    ///   - name: The name of the user
    ///   - email: The user's e-mail
    ///   - plan: The plan for the user
    ///   - location: Location data about the user
    ///   - customProperties: Custom attributes and metrics for the user's endpoint
    ///   - userAttributes: Attributes for the user
    public init(
        name: String? = nil,
        email: String? = nil,
        plan: String? = nil,
        location: UserProfileLocation? = nil,
        customProperties: [String: UserProfilePropertyValue]? = nil,
        userAttributes: [String: [String]]? = nil,
        optedOutOfMessages: Bool? = nil
    ) {
        self.name = name
        self.email = email
        self.plan = plan
        self.location = location
        self.customProperties = customProperties
        self.userAttributes = userAttributes
        self.optedOutOfMessages = optedOutOfMessages
    }
}
