//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Foundation
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSAPICategoryPlugin

import AWSPluginsCore

class AWSAPICategoryPluginTestBase: XCTestCase {

    var apiPlugin: AWSAPIPlugin!
    var authService: MockAWSAuthService!
    var pluginConfig: AWSAPICategoryPluginConfiguration!

    let apiName = "apiName"
    let baseURL = URL(fileURLWithPath: "path")
    let region = "us-east-1".aws_regionTypeValue()

    let testDocument = "query { getTodo { id name description }}"
    let testVariables = ["id": 123]

    let testBody = Data()
    let testPath = "testPath"

    override func setUp() {
        apiPlugin = AWSAPIPlugin()
        authService = MockAWSAuthService()
        do {
            let endpointConfig = [apiName: try AWSAPICategoryPluginConfiguration.EndpointConfig(
                name: apiName,
                baseURL: baseURL,
                region: region,
                authorizationType: AWSAuthorizationType.none,
                authorizationConfiguration: AWSAuthorizationConfiguration.none,
                endpointType: .graphQL)]
            pluginConfig = AWSAPICategoryPluginConfiguration(endpoints: endpointConfig)
            apiPlugin.configure(authService: authService,
                                pluginConfig: pluginConfig)
        } catch {
            XCTFail("Failed to create endpoint config")
        }

        Amplify.reset()
        let config = AmplifyConfiguration()
        do {
            try Amplify.configure(config)
        } catch {
            XCTFail("Error setting up Amplify: \(error)")
        }
    }
}
