//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Foundation
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSAPIPlugin
@testable import AWSPluginsTestCommon

import AWSPluginsCore

class AWSAPICategoryPluginTestBase: XCTestCase {

    var apiPlugin: AWSAPIPlugin!
    var authService: MockAWSAuthService!
    var pluginConfig: AWSAPICategoryPluginConfiguration!

    let apiName = "apiName"
    let baseURL = URL(fileURLWithPath: "path")
    let region = "us-east-1"

    let testDocument = "query { getTodo { id name description }}"
    let testVariables = ["id": 123]

    let testBody = Data()
    let testPath = "testPath"

    override func setUp() async throws {
        apiPlugin = AWSAPIPlugin()

        let authService = MockAWSAuthService()
        let apiAuthProvider = APIAuthProviderFactory()
        self.authService = authService

        do {
            let endpointConfig = [apiName: try AWSAPICategoryPluginConfiguration.EndpointConfig(
                name: apiName,
                baseURL: baseURL,
                region: region,
                authorizationType: AWSAuthorizationType.none,
                endpointType: .graphQL,
                apiAuthProviderFactory: apiAuthProvider)]
            let interceptors = [apiName: AWSAPIEndpointInterceptors(
                                    endpointName: apiName,
                                    apiAuthProviderFactory: apiAuthProvider)]
            let pluginConfig = AWSAPICategoryPluginConfiguration(endpoints: endpointConfig,
                                                                 interceptors: interceptors)
            self.pluginConfig = pluginConfig

            let dependencies = AWSAPIPlugin.ConfigurationDependencies(
                pluginConfig: pluginConfig,
                authService: authService,
                subscriptionConnectionFactory: AWSSubscriptionConnectionFactory(),
                logLevel: .error
            )
            apiPlugin.configure(using: dependencies)
        } catch {
            XCTFail("Failed to create endpoint config")
        }

        await Amplify.reset()
        // await Amplify.reset() doesn't immediately stop all in-progress tasks, so we sleep here to
        // give everything a chance to complete. This prevents sporadic failures when running many tests.
        sleep(2)
        let config = AmplifyConfiguration()
        do {
            try Amplify.configure(config)
        } catch {
            XCTFail("Error setting up Amplify: \(error)")
        }
    }

    override func tearDown() async throws {
        if let api = apiPlugin {
            api.reset()
        }
    }
}
