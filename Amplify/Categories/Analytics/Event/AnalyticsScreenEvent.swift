//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AnalyticsScreenEvent: AnalyticsEvent {

    /// Name of the event
    public var eventName: String

    /// The route representing the screen
    public var route: String?

    /// The referrer of the event
    public var referrer: String?

    /// Time it took to load the screen
    public var loadTime: Int?

    /// Properties of the event
    public var properties: [String: AnalyticsPropertyValue]?

    public init(eventName: String,
                properties: [String: AnalyticsPropertyValue]? = nil,
                route: String? = nil,
                referrer: String? = nil,
                loadTime: Int? = nil) {
        self.eventName = eventName
        self.properties = properties
        self.route = route
        self.referrer = referrer
        self.loadTime = loadTime
    }
}
