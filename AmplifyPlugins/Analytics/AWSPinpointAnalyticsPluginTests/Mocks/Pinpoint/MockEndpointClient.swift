//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import AWSPinpointAnalyticsPlugin
import AWSClientRuntime

// TODO: `EndpointClient` should be replaced with a protocol instead
class MockEndpointClient: EndpointClient {
    init() {
        let context = try! PinpointContext(with: PinpointContextConfiguration(appId: "appId"),
                                           credentialsProvider: MockCredentialsProvider(),
                                           region: "region")
        super.init(context: context)
    }
    
    class MockCredentialsProvider: CredentialsProvider {
        func getCredentials() async throws -> AWSCredentials {
            return AWSCredentials(accessKey: "", secret: "", expirationTimeout: 1000)
        }
    }
    
    var updateEndpointProfileCount = 0
    override func updateEndpointProfile() async throws {
        updateEndpointProfileCount += 1
    }
    
    func resetCounters() {
        updateEndpointProfileCount = 0
    }
}
