//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AnalyticsRevenueEvent: AnalyticsEvent {

    /// Name of the event
    public var eventName: String

    /// Identifier of the product
    public var productId: String

    /// Value of the product
    public var value: Double

    /// Revenue of the sale
    public var revenue: Double

    /// Amount sold of the product
    public var quantity: Int

    /// Currency of the sale
    public var currency: String

    /// Properties of the event
    public var properties: [String: AnalyticsPropertyValue]?

    public init(eventName: String,
                productId: String,
                value: Double,
                revenue: Double,
                quantity: Int,
                currency: String,
                properties: [String: AnalyticsPropertyValue]? = nil) {
        self.eventName = eventName
        self.productId = productId
        self.value = value
        self.revenue = revenue
        self.quantity = quantity
        self.currency = currency
        self.properties = properties
    }
    
}
