//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// <#Description#>
public struct BasicAnalyticsEvent: AnalyticsEvent {

    /// The name of the event
    public var name: String

    /// Properties of the event
    public var properties: AnalyticsProperties?

    /// <#Description#>
    /// - Parameters:
    ///   - name: <#name description#>
    ///   - properties: <#properties description#>
    public init(name: String,
                properties: AnalyticsProperties? = nil) {
        self.name = name
        self.properties = properties
    }
}
