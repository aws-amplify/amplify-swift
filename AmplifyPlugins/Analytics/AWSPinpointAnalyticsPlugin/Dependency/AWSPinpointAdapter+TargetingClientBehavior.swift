//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPinpoint
import Foundation

extension AWSPinpointAdapter: AWSPinpointTargetingClientBehavior {
    func currentEndpointProfile() -> AWSPinpointEndpointProfile {
        pinpoint.targetingClient.currentEndpointProfile()
    }

    func updateEndpointProfile() -> AWSTask<AnyObject> {
        pinpoint.targetingClient.updateEndpointProfile()
    }

    func update(_ endpointProfile: AWSPinpointEndpointProfile) -> AWSTask<AnyObject> {
        pinpoint.targetingClient.update(endpointProfile)
    }

    func addAttribute(_ theValue: [Any], forKey theKey: String) {
        pinpoint.targetingClient.addAttribute(theValue, forKey: theKey)
    }

    func removeAttribute(forKey theKey: String) {
        pinpoint.targetingClient.removeAttribute(forKey: theKey)
    }

    func addMetric(_ theValue: NSNumber, forKey theKey: String) {
        pinpoint.targetingClient.addMetric(theValue, forKey: theKey)
    }

    func removeMetric(forKey theKey: String) {
        pinpoint.targetingClient.removeMetric(forKey: theKey)
    }
}
