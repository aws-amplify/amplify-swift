//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Foundation
import AWSPluginsCore

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSAPICategoryPlugin

@available(iOS 13.0, *)
class AWSAPICategoryPluginReachabilityTests: XCTestCase {

    var apiPlugin: AWSAPIPlugin!

    override func setUp() {
        apiPlugin = AWSAPIPlugin()
    }

    override func tearDown() {
        if let api = apiPlugin {
            api.reset {
            }
        }
    }

    func testReachabilityReturnsGraphQLAPI() throws {
        let graphQLAPI = "graphQLAPI"
        do {
            let endpointConfig = [graphQLAPI: try getEndpointConfig(apiName: graphQLAPI, endpointType: .graphQL)]
            let pluginConfig = AWSAPICategoryPluginConfiguration(endpoints: endpointConfig)
            let dependencies = AWSAPIPlugin.ConfigurationDependencies(
                pluginConfig: pluginConfig,
                authService: MockAWSAuthService(),
                subscriptionConnectionFactory: AWSSubscriptionConnectionFactory()
            )
            apiPlugin.configure(using: dependencies)
        } catch {
            XCTFail("Failed to create endpoint config")
        }

        let publisher = try apiPlugin.reachabilityPublisher()
        XCTAssertNotNil(publisher)
        XCTAssertEqual(apiPlugin.reachabilityMap.count, 1)
        guard let reachability = apiPlugin.reachabilityMap.first else {
            return
        }
        XCTAssertEqual(reachability.key, graphQLAPI)
    }

    func testReachabilityReturnsGraphQLAPIForMultipleEndpoints() throws {
        let graphQLAPI = "graphQLAPI"
        let restAPI = "restAPI"
        do {
            let endpointConfig = [graphQLAPI: try getEndpointConfig(apiName: graphQLAPI, endpointType: .graphQL),
                                  restAPI: try getEndpointConfig(apiName: restAPI, endpointType: .rest)]
            let pluginConfig = AWSAPICategoryPluginConfiguration(endpoints: endpointConfig)
            let dependencies = AWSAPIPlugin.ConfigurationDependencies(
                pluginConfig: pluginConfig,
                authService: MockAWSAuthService(),
                subscriptionConnectionFactory: AWSSubscriptionConnectionFactory()
            )
            apiPlugin.configure(using: dependencies)
        } catch {
            XCTFail("Failed to create endpoint config")
        }

        let publisher = try apiPlugin.reachabilityPublisher()
        XCTAssertNotNil(publisher)
        XCTAssertEqual(apiPlugin.reachabilityMap.count, 1)
        guard let reachability = apiPlugin.reachabilityMap.first else {
            return
        }
        XCTAssertEqual(reachability.key, graphQLAPI)
    }

    // MARK: - Helpers

    func getEndpointConfig(apiName: String, endpointType: AWSAPICategoryPluginEndpointType) throws ->
    AWSAPICategoryPluginConfiguration.EndpointConfig {
        try AWSAPICategoryPluginConfiguration.EndpointConfig(
            name: apiName,
            baseURL: URL(string: "http://\(apiName)")!,
            region: nil,
            authorizationType: AWSAuthorizationType.none,
            authorizationConfiguration: AWSAuthorizationConfiguration.none,
            endpointType: endpointType,
            apiAuthProviderFactory: APIAuthProviderFactory())
    }
}
