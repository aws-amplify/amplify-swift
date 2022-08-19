//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

extension PinpointEvent {
    func asAnalyticsEvent() -> AnalyticsEvent {
        var properties: AnalyticsProperties = [:]

        for attribute in attributes {
            properties[attribute.key] = attribute.value
        }

        for metric in metrics {
            properties[metric.key] = metric.value
        }

        return BasicAnalyticsEvent(name: eventType,
                                   properties: properties)
    }
}

extension Array where Element == PinpointEvent {
    func asAnalyticsEventArray() -> [AnalyticsEvent] {
        map { $0.asAnalyticsEvent() }
    }
}
