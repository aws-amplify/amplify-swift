//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import AWSAPIPlugin

final class AWSAPIPluginConfigurationTests: XCTestCase {

    // Type-safe configuration of the plugin takes precendent over amplify configuration
    func testAmplifyConfigure() throws {
        
        // `amplifyconfiguration.json` is added to the target, and may contain other plugin configurations
        // ie. storage, auth, etc.
        
        // Create an in-memory AWSAPIPlugin configuration that will override any config
        // from `amplifyconfiguration.json`
        let configuration = AWSAPIPluginConfiguration(
            apis: ["apiName": .init(endpointType: .graphQL,
                                    endpoint: URL(string: urlString),
                                    region: "us-east-1",
                                    authorizationType: .userPool)])
        Amplify.add(plugin: AWSAPIPlugin(configuration: configuration))
        Amplify.configure()
    }
}
