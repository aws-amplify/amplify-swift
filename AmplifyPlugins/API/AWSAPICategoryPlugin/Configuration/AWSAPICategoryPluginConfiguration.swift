//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSPluginsCore

public struct AWSAPICategoryPluginConfiguration {
    let endpoints: [String: EndpointConfig]

    init(endpoints: [String: EndpointConfig]) {
        self.endpoints = endpoints
    }

    // TODO:
    /* from Tim:
     One of the intents of the AWSAuthorizationConfiguration is to obviate the need for config objects to directly
     know about auth service. Let's talk about this to see if we can remove the dependency. Perhaps we can create a
     configuration factory with the auth service, that can then be used to instantiate configurations when needed.
     */
    init(jsonValue: JSONValue, authService: AWSAuthService) throws {
        guard case .object(let config) = jsonValue else {
            throw PluginError.pluginConfigurationError(
                "Could not cast incoming configuration to a JSONValue `.object`",
                """
                The specified configuration is not convertible to a JSONValue. Review the configuration and ensure it \
                contains the expected values, and does not use any types that aren't convertible to a corresponding \
                JSONValue:
                \(jsonValue)
                """
            )
        }

        let endpoints = try AWSAPICategoryPluginConfiguration.endpointsFromConfig(config: config,
                                                                           authService: authService)
        self.init(endpoints: endpoints)
    }

    private static func endpointsFromConfig(config: [String: JSONValue],
                                            authService: AWSAuthService) throws -> [String: EndpointConfig] {
        var endpoints = [String: EndpointConfig]()

        for (key, jsonValue) in config {
            let name = key
            let endpointConfig = try EndpointConfig(name: name,
                                                    jsonValue: jsonValue,
                                                    authService: authService)
            endpoints[name] = endpointConfig
        }

        return endpoints
    }
}
