//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPinpoint
import Foundation
@testable import AWSPinpointAnalyticsPlugin
@_spi(InternalAWSPinpoint) @testable import InternalAWSPinpoint

extension MockAWSPinpoint {
    func currentEndpointProfile() -> PinpointEndpointProfile {
        currentEndpointProfileCalled += 1

        return PinpointEndpointProfile(applicationId: applicationId, endpointId: endpointId)
    }

    func updateEndpointProfile() async throws {
        updateEndpointProfileCalled += 1

        if case let .failure(error) = updateEndpointProfileResult {
            throw error
        }
    }

    func updateEndpoint(
        with endpointProfile: PinpointEndpointProfile,
        source: AWSPinpointSource
    ) async throws {
        updateEndpointProfileCalled += 1
        updateEndpointProfileValue = endpointProfile

        if case let .failure(error) = updateEndpointProfileResult {
            throw error
        }
    }

    func addAttributes(_ attributes: [String], forKey key: String) {
        addAttributeCalled += 1

        addAttributeValue = attributes
        addAttributeKey = key
    }

    func removeAttributes(forKey key: String) {
        removeAttributeCalled += 1

        removeAttributeKey = key
    }

    func addMetric(_ metric: Double, forKey key: String) {
        addMetricCalled += 1

        addMetricValue = metric
        addMetricKey = key
    }

    func removeMetric(forKey theKey: String) {
        removeMetricCalled += 1

        removeMetricKey = theKey
    }
}
