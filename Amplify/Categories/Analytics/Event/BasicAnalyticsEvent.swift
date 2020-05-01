//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct BasicAnalyticsEvent: AnalyticsEvent {

    /// The name of the event
    public var name: String

    /// Properties of the event
    public var properties: AnalyticsProperties?

    public init(name: String,
                properties: AnalyticsProperties? = nil) {
        self.name = name
        self.properties = properties
    }
}
