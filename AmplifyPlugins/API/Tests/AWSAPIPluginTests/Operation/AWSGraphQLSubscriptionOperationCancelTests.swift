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
class AWSGraphQLSubscriptionOperationCancelTests: XCTestCase {
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

        let receivedValueConnecting = expectation(description: "Received value for connecting")

        let valueListener: GraphQLSubscriptionOperation<JSONValue>.InProcessListener = { value in
            switch value {
            case .connection(let state):
                switch state {
                case .connecting:
                    print("1/3 Subscription is connecting")
                    receivedValueConnecting.fulfill()
                case .disconnected:
                    break
                default:
                    XCTFail("Unexpected value on value listener: \(state)")
                }
            default:
                XCTFail("Unexpected value on on value listener: \(value)")
            }
        }

        let completionListener: GraphQLSubscriptionOperation<JSONValue>.ResultListener = { _ in }

        let operation = apiPlugin.subscribe(
            request: request,
            valueListener: valueListener,
            completionListener: completionListener
        )
        await waitForExpectations(timeout: 5)
        
        let receivedCompletion = expectation(description: "Received completion")
        let receivedFailure = expectation(description: "Received failure")
        receivedFailure.isInverted = true
        let receivedValueDisconnected = expectation(description: "Received value for disconnected")
        
        _ = operation.subscribe(inProcessListener: { value in
            switch value {
            case .connection(let state):
                switch state {
                case .connecting:
                    XCTFail("Unexpected value on value listener: \(state)")
                case .disconnected:
                    print("2/3 Subscription is disconnected")
                    receivedValueDisconnected.fulfill()
                default:
                    XCTFail("Unexpected value on value listener: \(state)")
                }
            default:
                XCTFail("Unexpected value on on value listener: \(value)")
            }
        })
        _ = operation.subscribe(resultListener: { result in
            switch result {
            case .failure:
                receivedFailure.fulfill()
            case .success:
                print("3/3 Subscription is completed successfully")
                receivedCompletion.fulfill()
            }
        })
        
        operation.cancel()
        XCTAssert(operation.isCancelled)
        await waitForExpectations(timeout: 5)
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

        let receivedCompletion = expectation(description: "Received completion")
        receivedCompletion.isInverted = true
        let receivedFailure = expectation(description: "Received failure")
        let receivedValue = expectation(description: "Received value for connecting")
        receivedValue.isInverted = true

        let valueListener: GraphQLSubscriptionOperation<JSONValue>.InProcessListener = { _ in
            receivedValue.fulfill()
        }

        let completionListener: GraphQLSubscriptionOperation<JSONValue>.ResultListener = { result in
            switch result {
            case .failure:
                receivedFailure.fulfill()
            case .success:
                receivedCompletion.fulfill()
            }
        }

        let operation = apiPlugin.subscribe(
            request: request,
            valueListener: valueListener,
            completionListener: completionListener
        )
        await waitForExpectations(timeout: 0.3)
        XCTAssert(operation.isFinished)
    }

    func testCallingCancelWhileCreatingConnectionShouldCallCompletionListener() async {
        let connectionCreation = expectation(description: "connection factory called")
        let mockSubscriptionConnectionFactory = MockSubscriptionConnectionFactory(onGetOrCreateConnection: { _, _, _, _ in
            connectionCreation.fulfill()
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
        
        
        let receivedValue = expectation(description: "Received value for connecting")
        receivedValue.assertForOverFulfill = false

        let valueListener: GraphQLSubscriptionOperation<JSONValue>.InProcessListener = { _ in
            receivedValue.fulfill()
        }

        let operation = apiPlugin.subscribe(
            request: request,
            valueListener: valueListener,
            completionListener: nil
        )
        await waitForExpectations(timeout: 5)
        let receivedFailure = expectation(description: "Received failure")
        receivedFailure.isInverted = true
        let receivedCompletion = expectation(description: "Received completion")
        
        _ = operation.subscribe(resultListener: { result in
            switch result {
            case .failure:
                receivedFailure.fulfill()
            case .success:
                receivedCompletion.fulfill()
            }
        })
        
        operation.cancel()
        XCTAssert(operation.isCancelled)
        await waitForExpectations(timeout: 5)
    }
}
