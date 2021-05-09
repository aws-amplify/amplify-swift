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

    /// <#Description#>
    /// - Parameters:
    ///   - name: <#name description#>
    ///   - email: <#email description#>
    ///   - plan: <#plan description#>
    ///   - location: <#location description#>
    ///   - properties: <#properties description#>
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

        /// <#Description#>
        public var latitude: Double?

        /// <#Description#>
        public var longitude: Double?

        /// <#Description#>
        public var postalCode: String?

        /// <#Description#>
        public var city: String?

        /// <#Description#>
        public var region: String?

        /// <#Description#>
        public var country: String?

        /// <#Description#>
        /// - Parameters:
        ///   - latitude: <#latitude description#>
        ///   - longitude: <#longitude description#>
        ///   - postalCode: <#postalCode description#>
        ///   - city: <#city description#>
        ///   - region: <#region description#>
        ///   - country: <#country description#>
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
