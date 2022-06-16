//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSPinpointAnalyticsPlugin
import AWSClientRuntime

actor MockEndpointClient: EndpointClientBehaviour {
    class MockCredentialsProvider: CredentialsProvider {
        func getCredentials() async throws -> AWSCredentials {
            return AWSCredentials(accessKey: "", secret: "", expirationTimeout: 1000)
        }
    }
    
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
    
    func addAttributes(_ attributes: [String], forKey key: String) {}
    
    func removeAttributes(forKey key: String) {}
    
    func addMetric(_ metric: Double, forKey key: String) {}
    
    func removeMetric(forKey key: String) {}
}
