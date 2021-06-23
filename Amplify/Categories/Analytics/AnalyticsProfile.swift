//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// User specific data
public struct AnalyticsUserProfile {

    /// Name of the user
    public var name: String?

    /// The user's email
    public var email: String?

    /// The plan for the user
    public var plan: String?

    /// Location data about the user
    public var location: Location?

    /// Properties of the user profile
    public var properties: AnalyticsProperties?

    /// Initializer
    /// - Parameters:
    ///   - name: Name of user
    ///   - email: The user's e-mail
    ///   - plan: The plan for the user
    ///   - location: Location data about the user
    ///   - properties: Properties of the user profile
    public init(name: String? = nil,
                email: String? = nil,
                plan: String? = nil,
                location: Location?,
                properties: AnalyticsProperties? = nil) {
        self.name = name
        self.email = email
        self.plan = plan
        self.location = location
        self.properties = properties
    }
}

extension AnalyticsUserProfile {

    /// Location specific data
    public struct Location {

        /// The user's latitude
        public var latitude: Double?

        /// The user's longitude
        public var longitude: Double?

        /// The user's postal code
        public var postalCode: String?

        /// The user's city
        public var city: String?

        /// The user's region
        public var region: String?

        /// The user's country
        public var country: String?

        /// Initializer
        /// - Parameters:
        ///   - latitude: The user's latitude
        ///   - longitude: The user's longitude
        ///   - postalCode: The user's postal code
        ///   - city: The user's city
        ///   - region: The user's region
        ///   - country: The user's country
        public init(latitude: Double? = nil,
                    longitude: Double? = nil,
                    postalCode: String? = nil,
                    city: String? = nil,
                    region: String? = nil,
                    country: String? = nil) {
            self.latitude = latitude
            self.longitude = longitude
            self.postalCode = postalCode
            self.city = city
            self.region = region
            self.country = country
        }
    }
}
