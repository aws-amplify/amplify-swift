//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPluginsCore
import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSAPIPlugin

// swiftlint:disable:next type_name
class AWSAPICategoryPluginConfigurationEndpointConfigTests: XCTestCase {

    let graphQLAPI = "graphQLAPI"
    let graphQLAPI2 = "graphQLAPI2"
    let restAPI = "restAPI"
    let restAPI2 = "restAPI2"

    func testGetConfigAPIName() throws {
        let endpointConfig = try [graphQLAPI: getEndpointConfig(apiName: graphQLAPI, endpointType: .graphQL)]

        let endpoint = try endpointConfig.getConfig(for: graphQLAPI)

        XCTAssertEqual(endpoint.name, graphQLAPI)
        XCTAssertEqual(endpoint.endpointType, .graphQL)
    }

    func testGetConfigAPINameFailsWhenInvalidAPIName() throws {
        let endpointConfig = try [graphQLAPI: getEndpointConfig(apiName: graphQLAPI, endpointType: .graphQL)]

        do {
             _ = try endpointConfig.getConfig(for: "incorrectAPIName")
        } catch let error as APIError {
            guard case .invalidConfiguration = error else {
                XCTFail("Unexpected error \(error)")
                return
            }
        } catch {
            XCTFail("Should have been APIError")
        }
    }

    func testGetConfigEndpointTypeForGraphQL() throws {
        let endpointConfig = try [
            graphQLAPI: getEndpointConfig(apiName: graphQLAPI, endpointType: .graphQL),
            restAPI: getEndpointConfig(apiName: restAPI, endpointType: .rest)
        ]

        let endpoint = try endpointConfig.getConfig(endpointType: .graphQL)

        XCTAssertEqual(endpoint.name, graphQLAPI)
        XCTAssertEqual(endpoint.endpointType, .graphQL)
    }

    func testGetConfigEndpointTypeFailsWhenMoreThanOneEndpointOfTheTypeExists() throws {
        let endpointConfig = try [
            graphQLAPI: getEndpointConfig(apiName: graphQLAPI, endpointType: .graphQL),
            graphQLAPI2: getEndpointConfig(apiName: graphQLAPI2, endpointType: .graphQL)
        ]

        do {
             _ = try endpointConfig.getConfig(endpointType: .graphQL)
        } catch let error as APIError {
            guard case .invalidConfiguration = error else {
                XCTFail("Unexpected error \(error)")
                return
            }
        } catch {
            XCTFail("Should have been APIError")
        }
    }

    func testGetConfigEndpointTypeFailsWhenMissingEndpointForType() throws {
        let endpointConfig = try [restAPI: getEndpointConfig(apiName: restAPI, endpointType: .rest)]

        do {
             _ = try endpointConfig.getConfig(endpointType: .graphQL)
        } catch let error as APIError {
            guard case .invalidConfiguration = error else {
                XCTFail("Unexpected error \(error)")
                return
            }
        } catch {
            XCTFail("Should have been APIError")
        }
    }

    func testGetConfigEndpointTypeForREST() throws {
        let endpointConfig = try [restAPI: getEndpointConfig(apiName: restAPI, endpointType: .rest)]

        let endpoint = try endpointConfig.getConfig(endpointType: .rest)

        XCTAssertEqual(endpoint.name, restAPI)
        XCTAssertEqual(endpoint.endpointType, .rest)
    }

    func testGetConfigForOneGraphQLAndOneRESTEndpoint() throws {
        let endpointConfig = try [
            graphQLAPI: getEndpointConfig(apiName: graphQLAPI, endpointType: .graphQL),
            restAPI: getEndpointConfig(apiName: restAPI, endpointType: .rest)
        ]

        let endpoint = try endpointConfig.getConfig()

        XCTAssertEqual(endpoint.name, graphQLAPI)
        XCTAssertEqual(endpoint.endpointType, .graphQL)
    }

    func testGetConfigForMoreThanOneGraphQLAndOneRESTEndpoint() throws {
        let endpointConfig = try [
            graphQLAPI: getEndpointConfig(apiName: graphQLAPI, endpointType: .graphQL),
            graphQLAPI2: getEndpointConfig(apiName: graphQLAPI2, endpointType: .graphQL),
            restAPI: getEndpointConfig(apiName: restAPI, endpointType: .rest)
        ]

        let endpoint = try endpointConfig.getConfig()

        XCTAssertEqual(endpoint.name, restAPI)
        XCTAssertEqual(endpoint.endpointType, .rest)
    }

    func testGetConfigForOneGraphQLAndMoreThanOneRESTEndpoint() throws {
        let endpointConfig = try [
            graphQLAPI: getEndpointConfig(apiName: graphQLAPI, endpointType: .graphQL),
            restAPI: getEndpointConfig(apiName: restAPI, endpointType: .rest),
            restAPI2: getEndpointConfig(apiName: restAPI2, endpointType: .rest)
        ]

        let endpoint = try endpointConfig.getConfig()

        XCTAssertEqual(endpoint.name, graphQLAPI)
        XCTAssertEqual(endpoint.endpointType, .graphQL)
    }

    func testGetConfigShouldFailForMoreThanOneGraphQLAndRESTEndpoints() throws {
        let endpointConfig = try [
            graphQLAPI: getEndpointConfig(apiName: graphQLAPI, endpointType: .graphQL),
            graphQLAPI2: getEndpointConfig(apiName: graphQLAPI2, endpointType: .graphQL),
            restAPI: getEndpointConfig(apiName: restAPI, endpointType: .rest),
            restAPI2: getEndpointConfig(apiName: restAPI2, endpointType: .rest)
        ]

        do {
             _ = try endpointConfig.getConfig()
        } catch let error as APIError {
            guard case .invalidConfiguration = error else {
                XCTFail("Unexpected error \(error)")
                return
            }
        } catch {
            XCTFail("Should have been APIError")
        }
    }

    // MARK: - Helpers

    func getEndpointConfig(apiName: String, endpointType: AWSAPICategoryPluginEndpointType) throws ->
    AWSAPICategoryPluginConfiguration.EndpointConfig {
        try AWSAPICategoryPluginConfiguration.EndpointConfig(
            name: apiName,
            baseURL: URL(string: "http://myhost")!,
            region: nil,
            authorizationType: AWSAuthorizationType.none,
            endpointType: endpointType,
            apiAuthProviderFactory: APIAuthProviderFactory()
        )
    }
}
