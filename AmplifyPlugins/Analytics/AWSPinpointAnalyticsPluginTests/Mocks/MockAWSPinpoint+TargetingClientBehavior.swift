//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPinpoint
@testable import AWSPinpointAnalyticsPlugin
import Foundation

extension MockAWSPinpoint: AWSPinpointTargetingClientBehavior {
    public func currentEndpointProfile() -> AWSPinpointEndpointProfile {
        currentEndpointProfileCalled += 1

        return AWSPinpointEndpointProfile(applicationId: applicationId, endpointId: endpointId)
    }

    public func updateEndpointProfile() -> AWSTask<AnyObject> {
        updateEndpointProfileCalled += 1

        if let result = updateEndpointProfileResult {
            return result
        }

        return AWSTask<AnyObject>.init(result: "" as AnyObject)
    }

    public func update(_ endpointProfile: AWSPinpointEndpointProfile) -> AWSTask<AnyObject> {
        updateEndpointProfileCalled += 1
        updateEndpointProfileValue = endpointProfile

        if let result = updateEndpointProfileResult {
            return result
        }

        return AWSTask<AnyObject>.init(result: "" as AnyObject)
    }

    public func addAttribute(_ theValue: [Any], forKey theKey: String) {
        addAttributeCalled += 1

        addAttributeValue = theValue
        addAttributeKey = theKey
    }

    public func removeAttribute(forKey theKey: String) {
        removeAttributeCalled += 1

        removeAttributeKey = theKey
    }

    public func addMetric(_ theValue: NSNumber, forKey theKey: String) {
        addMetricCalled += 1

        addMetricValue = theValue
        addMetricKey = theKey
    }

    public func removeMetric(forKey theKey: String) {
        removeMetricCalled += 1

        removeMetricKey = theKey
    }
}
