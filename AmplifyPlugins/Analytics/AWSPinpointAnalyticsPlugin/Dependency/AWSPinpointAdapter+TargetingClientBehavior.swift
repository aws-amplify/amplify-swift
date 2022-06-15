//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPinpoint
import Foundation

extension AWSPinpointAdapter: AWSPinpointTargetingClientBehavior {
    func currentEndpointProfile() -> PinpointEndpointProfile {
        pinpoint.targetingClient.currentEndpointProfile()
    }

    func updateEndpointProfile() async throws {
        try await pinpoint.targetingClient.updateEndpointProfile()
    }

    func update(_ endpointProfile: PinpointEndpointProfile) async throws {
        try await pinpoint.targetingClient.update(endpointProfile)
    }

    func addAttributes(_ attributes: [Any], forKey key: String) {
        pinpoint.targetingClient.addAttributes(attributes, forKey: key)
    }

    func removeAttributes(forKey key: String) {
       pinpoint.targetingClient.removeAttributes(forKey: key)
    }

    func addMetric(_ metric: Double, forKey key: String) {
        pinpoint.targetingClient.addMetric(metric, forKey: key)
    }

    func removeMetric(forKey key: String) {
        pinpoint.targetingClient.removeMetric(forKey: key)
    }
}
