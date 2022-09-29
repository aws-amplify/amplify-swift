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
@testable import AppSyncRealTimeClient
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

    func setUp(subscriptionConnectionFactory: SubscriptionConnectionFactory) async {
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
                subscriptionConnectionFactory: subscriptionConnectionFactory,
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
    
    func testCancelSendsCompletion() async {
        let mockSubscriptionConnectionFactory = MockSubscriptionConnectionFactory(onGetOrCreateConnection: { _, _, _, _ in
            return MockSubscriptionConnection(onSubscribe: { (_, _, eventHandler) -> SubscriptionItem in
                let item = SubscriptionItem(requestString: "", variables: nil, eventHandler: { _, _ in
                })
                eventHandler(.connection(.connecting), item)
                return item
            }, onUnsubscribe: {_ in
            })
        })
        await setUp(subscriptionConnectionFactory: mockSubscriptionConnectionFactory)

        let request = GraphQLRequest(apiName: apiName,
                                     document: testDocument,
                                     variables: nil,
                                     responseType: JSONValue.self)

        let receivedValueConnecting = asyncExpectation(description: "Received value for connecting")
        let receivedValueDisconnected = asyncExpectation(description: "Received value for disconnected")
        let receivedCompletion = asyncExpectation(description: "Received completion")
        let receivedFailure = asyncExpectation(description: "Received failure", isInverted: true)
        let subscriptionEvents = apiPlugin.subscribe(request: request)
        Task {
            do {
                for try await subscriptionEvent in subscriptionEvents {
                    switch subscriptionEvent {
                    case .connection(let state):
                        switch state {
                        case .connecting:
                            await receivedValueConnecting.fulfill()
                        case .disconnected:
                            await receivedValueDisconnected.fulfill()
                        default:
                            XCTFail("Unexpected value on value listener: \(state)")
                        }
                    default:
                        XCTFail("Unexpected value on on value listener: \(subscriptionEvent)")
                    }
                }
                await receivedCompletion.fulfill()
            } catch {
                await receivedFailure.fulfill()
            }
        }
        await waitForExpectations([receivedValueConnecting])
        subscriptionEvents.cancel()
        await waitForExpectations([receivedFailure], timeout: 0.1)
        await waitForExpectations([receivedValueDisconnected, receivedCompletion])
    }
    
    func testFailureOnConnection() async {
        let mockSubscriptionConnectionFactory = MockSubscriptionConnectionFactory(onGetOrCreateConnection: { _, _, _, _ in
            throw APIError.invalidConfiguration("something went wrong", "", nil)
        })

        await setUp(subscriptionConnectionFactory: mockSubscriptionConnectionFactory)

        let request = GraphQLRequest(apiName: apiName,
                                     document: testDocument,
                                     variables: nil,
                                     responseType: JSONValue.self)

        let receivedCompletion = asyncExpectation(description: "Received completion", isInverted: true)
        let receivedFailure = asyncExpectation(description: "Received failure")
        let receivedValue = asyncExpectation(description: "Received value for connecting", isInverted: true)

        let subscriptionEvents = apiPlugin.subscribe(request: request)
        Task {
            do {
                for try await _ in subscriptionEvents {
                    await receivedValue.fulfill()
                }
                await receivedCompletion.fulfill()
            } catch {
                await receivedFailure.fulfill()
            }
        }

        await waitForExpectations([receivedValue, receivedCompletion], timeout: 0.1)
        await waitForExpectations([receivedFailure])
    }

    func testCallingCancelWhileCreatingConnectionShouldCallCompletionListener() async {
        let connectionCreation = asyncExpectation(description: "connection factory called")
        let mockSubscriptionConnectionFactory = MockSubscriptionConnectionFactory(onGetOrCreateConnection: { _, _, _, _ in
            Task { await connectionCreation.fulfill() }
            return MockSubscriptionConnection(onSubscribe: { (_, _, eventHandler) -> SubscriptionItem in
                let item = SubscriptionItem(requestString: "", variables: nil, eventHandler: { _, _ in
                })
                eventHandler(.connection(.connecting), item)
                return item
            }, onUnsubscribe: {_ in
            })
        })

        await setUp(subscriptionConnectionFactory: mockSubscriptionConnectionFactory)

        let request = GraphQLRequest(apiName: apiName,
                                     document: testDocument,
                                     variables: nil,
                                     responseType: JSONValue.self)
        
        let receivedValue = asyncExpectation(description: "Received value for connecting", expectedFulfillmentCount: 1)
        let receivedFailure = asyncExpectation(description: "Received failure", isInverted: true)
        let receivedCompletion = asyncExpectation(description: "Received completion")
        
        let subscriptionEvents = apiPlugin.subscribe(request: request)
        Task {
            do {
                for try await _ in subscriptionEvents {
                    await receivedValue.fulfill()
                }
                await receivedCompletion.fulfill()
            } catch {
                await receivedFailure.fulfill()
            }
        }
        await waitForExpectations([receivedValue, connectionCreation])
        subscriptionEvents.cancel()
        await waitForExpectations([receivedFailure], timeout: 0.1)
        await waitForExpectations([receivedCompletion])
    }
}
