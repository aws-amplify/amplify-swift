//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol AnalyticsEvent {
    var name: String { get }
    var attributes: [String: String]? { get }
    var metrics: [String: NSNumber]? { get }
}

public struct BasicAnalyticsEvent: AnalyticsEvent {
    public var name: String
    public var attributes: [String: String]?
    public var metrics: [String: NSNumber]?

    public init(_ name: String,
                attributes: [String: String]? = nil,
                metrics: [String: NSNumber]? = nil) {
        self.name = name
        self.attributes = attributes
        self.metrics = metrics
    }
}
