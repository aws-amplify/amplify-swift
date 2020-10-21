//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSPluginsCore

public struct AWSAPICategoryPluginConfiguration {
    var endpoints: [String: EndpointConfig]

    init(endpoints: [String: EndpointConfig]) {
        self.endpoints = endpoints
    }

    init(jsonValue: JSONValue,
         apiAuthProviderFactory: APIAuthProviderFactory,
         authService: AWSAuthServiceBehavior) throws {
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
                                                                                  apiAuthProviderFactory: apiAuthProviderFactory,
                                                                                  authService: authService)
        self.init(endpoints: endpoints)
    }

    private static func endpointsFromConfig(
        config: [String: JSONValue],
        apiAuthProviderFactory: APIAuthProviderFactory,
        authService: AWSAuthServiceBehavior
    ) throws -> [String: EndpointConfig] {
        var endpoints = [String: EndpointConfig]()

        for (key, jsonValue) in config {
            let name = key
            let endpointConfig = try EndpointConfig(name: name,
                                                    jsonValue: jsonValue,
                                                    apiAuthProviderFactory: apiAuthProviderFactory,
                                                    authService: authService)
            endpoints[name] = endpointConfig
        }

        return endpoints
    }
}
