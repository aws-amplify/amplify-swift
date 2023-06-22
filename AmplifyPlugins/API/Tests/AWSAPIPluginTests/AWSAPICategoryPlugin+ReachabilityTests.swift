////
//// Copyright Amazon.com Inc. or its affiliates.
//// All Rights Reserved.
////
//// SPDX-License-Identifier: Apache-2.0
////
//
//import XCTest
//import Foundation
//import AWSPluginsCore
//
//@testable import Amplify
//@testable import AmplifyTestCommon
//@testable import AWSAPIPlugin
//@testable import AWSPluginsTestCommon
//
//class AWSAPICategoryPluginReachabilityTests: XCTestCase {
//
//    var apiPlugin: AWSAPIPlugin!
//
//    override func setUp() {
//        apiPlugin = AWSAPIPlugin()
//    }
//
//    override func tearDown() async throws {
//        if let api = apiPlugin {
//            await api.reset()
//        }
//    }
//
//    func testReachabilityReturnsGraphQLAPI() throws {
//        let graphQLAPI = "graphQLAPI"
//        do {
//            let endpointConfig = [graphQLAPI: try getEndpointConfig(apiName: graphQLAPI, endpointType: .graphQL)]
//            let pluginConfig = AWSAPICategoryPluginConfiguration(endpoints: endpointConfig)
//            let dependencies = AWSAPIPlugin.ConfigurationDependencies(
//                pluginConfig: pluginConfig,
//                authService: MockAWSAuthService(),
//                subscriptionConnectionFactory: AWSSubscriptionConnectionFactory(),
//                logLevel: .error
//            )
//            apiPlugin.configure(using: dependencies)
//        } catch {
//            XCTFail("Failed to create endpoint config")
//        }
//
//        let publisher = try apiPlugin.reachabilityPublisher()
//        XCTAssertNotNil(publisher)
//        XCTAssertEqual(apiPlugin.reachabilityMap.count, 1)
//        guard let reachability = apiPlugin.reachabilityMap.first else {
//            XCTFail("Missing expeected `reachability`")
//            return
//        }
//        XCTAssertEqual(reachability.key, graphQLAPI)
//    }
//
//    func testReachabilityReturnsGraphQLAPIForMultipleEndpoints() throws {
//        let graphQLAPI = "graphQLAPI"
//        let restAPI = "restAPI"
//        do {
//            let endpointConfig = [graphQLAPI: try getEndpointConfig(apiName: graphQLAPI, endpointType: .graphQL),
//                                  restAPI: try getEndpointConfig(apiName: restAPI, endpointType: .rest)]
//            let pluginConfig = AWSAPICategoryPluginConfiguration(endpoints: endpointConfig)
//            let dependencies = AWSAPIPlugin.ConfigurationDependencies(
//                pluginConfig: pluginConfig,
//                authService: MockAWSAuthService(),
//                subscriptionConnectionFactory: AWSSubscriptionConnectionFactory(),
//                logLevel: .error
//            )
//            apiPlugin.configure(using: dependencies)
//        } catch {
//            XCTFail("Failed to create endpoint config")
//        }
//
//        let publisher = try apiPlugin.reachabilityPublisher()
//        XCTAssertNotNil(publisher)
//        XCTAssertEqual(apiPlugin.reachabilityMap.count, 1)
//        guard let reachability = apiPlugin.reachabilityMap.first else {
//            XCTFail("Missing expeected `reachability`")
//            return
//        }
//        XCTAssertEqual(reachability.key, graphQLAPI)
//    }
//
//    func testReachabilityConcurrentPerform() throws {
//        let graphQLAPI = "graphQLAPI"
//        let restAPI = "restAPI"
//        do {
//            let endpointConfig = [graphQLAPI: try getEndpointConfig(apiName: graphQLAPI, endpointType: .graphQL),
//                                  restAPI: try getEndpointConfig(apiName: restAPI, endpointType: .rest)]
//            let pluginConfig = AWSAPICategoryPluginConfiguration(endpoints: endpointConfig)
//            let dependencies = AWSAPIPlugin.ConfigurationDependencies(
//                pluginConfig: pluginConfig,
//                authService: MockAWSAuthService(),
//                subscriptionConnectionFactory: AWSSubscriptionConnectionFactory(),
//                logLevel: .error
//            )
//            apiPlugin.configure(using: dependencies)
//        } catch {
//            XCTFail("Failed to create endpoint config")
//        }
//
//        let concurrentPerformCompleted = expectation(description: "concurrent perform completed")
//        concurrentPerformCompleted.expectedFulfillmentCount = 1_000
//        DispatchQueue.concurrentPerform(iterations: 1_000) { _ in
//            do {
//                let graphQLAPIPublisher = try apiPlugin.reachabilityPublisher(for: graphQLAPI)
//                XCTAssertNotNil(graphQLAPIPublisher)
//                let restAPIPublisher = try apiPlugin.reachabilityPublisher(for: restAPI)
//                XCTAssertNotNil(restAPIPublisher)
//            } catch {
//                XCTFail("\(error)")
//            }
//            concurrentPerformCompleted.fulfill()
//
//        }
//        wait(for: [concurrentPerformCompleted], timeout: 1)
//        XCTAssertEqual(apiPlugin.reachabilityMap.count, 2)
//    }
//
//    // MARK: - Helpers
//
//    func getEndpointConfig(apiName: String, endpointType: AWSAPICategoryPluginEndpointType) throws ->
//    AWSAPICategoryPluginConfiguration.EndpointConfig {
//        try AWSAPICategoryPluginConfiguration.EndpointConfig(
//            name: apiName,
//            baseURL: URL(string: "http://\(apiName)")!,
//            region: nil,
//            authorizationType: AWSAuthorizationType.none,
//            endpointType: endpointType,
//            apiAuthProviderFactory: APIAuthProviderFactory())
//    }
//}
