//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(InternalAWSPinpoint) @testable import InternalAWSPinpoint
import AWSClientRuntime
import AWSPinpoint
import Foundation

actor MockEndpointClient: EndpointClientBehaviour {
    let pinpointClient: PinpointClientProtocol = MockPinpointClient()

    var updateEndpointProfileCount = 0
    func updateEndpointProfile() async throws {
        updateEndpointProfileCount += 1
    }

    func resetCounters() {
        updateEndpointProfileCount = 0
    }

    var currentEndpointProfileCount = 0
    var mockedEndpointProfile: PinpointEndpointProfile?
    func currentEndpointProfile() -> PinpointEndpointProfile {
        currentEndpointProfileCount += 1
        return mockedEndpointProfile ?? PinpointEndpointProfile(applicationId: "", endpointId: "")
    }

    var updateEndpointProfileWithCount = 0
    func updateEndpointProfile(with endpointProfile: PinpointEndpointProfile) async throws {
        updateEndpointProfileWithCount += 1
    }


    nonisolated func convertToPublicEndpoint(_ endpointProfile: PinpointEndpointProfile) -> PinpointClientTypes.PublicEndpoint {
        return PinpointClientTypes.PublicEndpoint()
    }
}
