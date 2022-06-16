//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPinpoint
import Foundation

extension AWSPinpointAdapter: AWSPinpointTargetingClientBehavior {
    func currentEndpointProfile() async -> PinpointEndpointProfile {
        await pinpoint.endpointClient.currentEndpointProfile()
    }

    func updateEndpointProfile() async throws {
        try await pinpoint.endpointClient.updateEndpointProfile()
    }

    func update(_ endpointProfile: PinpointEndpointProfile) async throws {
        try await pinpoint.endpointClient.updateEndpointProfile(with: endpointProfile)
    }

    func addAttributes(_ attributes: [String], forKey key: String) async {
        await pinpoint.endpointClient.addAttributes(attributes, forKey: key)
    }

    func removeAttributes(forKey key: String) async {
        await pinpoint.endpointClient.removeAttributes(forKey: key)
    }

    func addMetric(_ metric: Double, forKey key: String) async {
        await pinpoint.endpointClient.addMetric(metric, forKey: key)
    }

    func removeMetric(forKey key: String) async {
        await pinpoint.endpointClient.removeMetric(forKey: key)
    }
}
