//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
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

        public var latitude: Double?

        public var longitude: Double?

        public var postalCode: String?

        public var city: String?

        public var region: String?

        public var country: String?

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
