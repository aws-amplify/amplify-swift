//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct BasicAnalyticsEvent: AnalyticsEvent {

    /// The name of the event
    public var eventName: String

    /// Properties of the event
    public var properties: [String: AnalyticsPropertyValue]?

    public init(_ eventName: String,
                properties: [String: AnalyticsPropertyValue]? = nil) {
        self.eventName = eventName
        self.properties = properties
    }
}
