//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSAPIPlugin
@testable import AmplifyTestCommon
@testable import AWSPluginsCore
@testable import AWSPluginsTestCommon

// swiftlint:disable:next type_name
class AWSGraphQLSubscriptionTaskRunnerCancelTests: XCTestCase {
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

    func setUp(appSyncRealTimeClientFactory: AppSyncRealTimeClientFactoryProtocol) async {
        apiPlugin = AWSAPIPlugin()

        let authService = MockAWSAuthService()
        self.authService = authService

        do {
            let endpointConfig = [apiName: try AWSAPICategoryPluginConfiguration.EndpointConfig(
                name: apiName,
                baseURL: baseURL,
                region: region,
                authorizationType: AWSAuthorizationType.none,
                endpointType: .graphQL,
                apiAuthProviderFactory: APIAuthProviderFactory())]
            let pluginConfig = AWSAPICategoryPluginConfiguration(endpoints: endpointConfig)
            self.pluginConfig = pluginConfig

            let dependencies = AWSAPIPlugin.ConfigurationDependencies(
                pluginConfig: pluginConfig,
                authService: authService,
                appSyncRealTimeClientFactory: appSyncRealTimeClientFactory,
                logLevel: .error
            )
            apiPlugin.configure(using: dependencies)
        } catch {
            XCTFail("Failed to create endpoint config")
        }

        await Amplify.reset()
        let config = AmplifyConfiguration()
        do {
            try Amplify.configure(config)
        } catch {
            XCTFail("Error setting up Amplify: \(error)")
        }
    }
    
    func testCancelSendsCompletion() async throws {
        let mockSubscriptionConnectionFactory = MockSubscriptionConnectionFactory(onGetOrCreateConnection: { _, _, _, _, _ in
            return MockAppSyncRealTimeClient()
        })

        await setUp(appSyncRealTimeClientFactory: mockSubscriptionConnectionFactory)

        let request = GraphQLRequest(apiName: apiName,
                                     document: testDocument,
                                     variables: nil,
                                     responseType: JSONValue.self)

        let receivedValueConnecting = expectation(description: "Received value for connecting")
        let receivedValueDisconnected = expectation(description: "Received value for disconnected")
        let receivedCompletion = expectation(description: "Received completion")
        let receivedFailure = expectation(description: "Received failure")
        receivedFailure.isInverted = true
        let subscriptionEvents = apiPlugin.subscribe(request: request)
        Task {
            do {
                for try await subscriptionEvent in subscriptionEvents {
                    switch subscriptionEvent {
                    case .connection(let state):
                        switch state {
                        case .connecting:
                            receivedValueConnecting.fulfill()
                        case .disconnected:
                            receivedValueDisconnected.fulfill()
                        default:
                            XCTFail("Unexpected value on value listener: \(state)")
                        }
                    default:
                        XCTFail("Unexpected value on on value listener: \(subscriptionEvent)")
                    }
                }
                receivedCompletion.fulfill()
            } catch {
                receivedFailure.fulfill()
            }
        }
        await fulfillment(of: [receivedValueConnecting], timeout: 1)
        subscriptionEvents.cancel()
        try await MockAppSyncRealTimeClient.waitForUnsubscirbed()
        await fulfillment(of: [receivedValueDisconnected, receivedCompletion, receivedFailure], timeout: 1)
    }
    
    func testFailureOnConnection() async {
        let mockAppSyncRealTimeClientFactory = MockSubscriptionConnectionFactory(onGetOrCreateConnection: { _, _, _, _, _ in
            throw APIError.invalidConfiguration("something went wrong", "", nil)
        })

        await setUp(appSyncRealTimeClientFactory: mockAppSyncRealTimeClientFactory)

        let request = GraphQLRequest(apiName: apiName,
                                     document: testDocument,
                                     variables: nil,
                                     responseType: JSONValue.self)

        let receivedCompletion = expectation(description: "Received completion")
        receivedCompletion.isInverted = true
        let receivedFailure = expectation(description: "Received failure")
        let receivedValue = expectation(description: "Received value for connecting")
        receivedValue.isInverted = true

        let subscriptionEvents = apiPlugin.subscribe(request: request)
        Task {
            do {
                for try await _ in subscriptionEvents {
                    receivedValue.fulfill()
                }
                receivedCompletion.fulfill()
            } catch {
                receivedFailure.fulfill()
            }
        }
        
        await fulfillment(of: [receivedValue, receivedFailure, receivedCompletion], timeout: 0.3)
    }

    func testCallingCancelWhileCreatingConnectionShouldCallCompletionListener() async {
        let connectionCreation = expectation(description: "connection factory called")
        let mockSubscriptionConnectionFactory = MockSubscriptionConnectionFactory(onGetOrCreateConnection: { _, _, _, _, _ in
            connectionCreation.fulfill()
            return MockAppSyncRealTimeClient()
        })

        await setUp(appSyncRealTimeClientFactory: mockSubscriptionConnectionFactory)

        let request = GraphQLRequest(apiName: apiName,
                                     document: testDocument,
                                     variables: nil,
                                     responseType: JSONValue.self)
        
        let receivedValue = expectation(description: "Received value for connecting")
        receivedValue.expectedFulfillmentCount = 1
        receivedValue.assertForOverFulfill = false

        let receivedFailure = expectation(description: "Received failure")
        receivedFailure.isInverted = true

        let receivedCompletion = expectation(description: "Received completion")
        
        let subscriptionEvents = apiPlugin.subscribe(request: request)
        Task {
            do {
                for try await _ in subscriptionEvents {
                    receivedValue.fulfill()
                }
                receivedCompletion.fulfill()
            } catch {
                receivedFailure.fulfill()
            }
        }
        await fulfillment(of: [receivedValue, connectionCreation], timeout: 5)
        subscriptionEvents.cancel()
        await fulfillment(of: [receivedFailure, receivedCompletion], timeout: 5)
    }
}
