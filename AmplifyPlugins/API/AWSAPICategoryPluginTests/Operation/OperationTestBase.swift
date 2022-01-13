//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import AWSPluginsTestCommon
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSAPIPlugin

class OperationTestBase: XCTestCase {

    var apiPlugin: AWSAPIPlugin!

    /// There are no throwing methods in this, but in order to let subclasses have a predictable way
    /// of setting up plugins, this base class uses `setUpWithError` instead of `setUp`. (XCTest
    /// lifecycle normally invokes `setUp` after `setUpWithError`, which means that any state config
    /// done inside of a subclass' `setUpWithError` could be erased by this class' call to
    /// `AWSAPIPlugin.reset` from inside `setUp`.
    override func setUpWithError() throws {
        if apiPlugin != nil {
            let waitForReset = DispatchSemaphore(value: 0)
            apiPlugin.reset {
                waitForReset.signal()
            }
            waitForReset.wait()
        }
        apiPlugin = nil
    }

    func setUpPlugin(
        sessionFactory: URLSessionBehaviorFactory? = nil,
        subscriptionConnectionFactory: SubscriptionConnectionFactory? = nil,
        endpointType: AWSAPICategoryPluginEndpointType
    ) throws {
        apiPlugin = AWSAPIPlugin(sessionFactory: sessionFactory)

        let configurationValues: JSONValue = [
            "Valid": [
                "endpointType": .string(endpointType.rawValue),
                "endpoint": "http://www.example.com",
                "authorizationType": "API_KEY",
                "apiKey": "SpecialApiKey33"
            ]
        ]

        let dependencies = try AWSAPIPlugin.ConfigurationDependencies(
            configurationValues: configurationValues,
            apiAuthProviderFactory: APIAuthProviderFactory(),
            authService: MockAWSAuthService(),
            subscriptionConnectionFactory: subscriptionConnectionFactory
        )

        apiPlugin.configure(using: dependencies)
    }

    func setUpPluginForSingleResponse(
        sending data: Data,
        for endpointType: AWSAPICategoryPluginEndpointType
    ) throws {
        let task = try makeSingleValueSuccessMockTask(sending: data)
        let mockSession = MockURLSession(onTaskForRequest: { _ in task })
        let sessionFactory = MockSessionFactory(returning: mockSession)
        try setUpPlugin(sessionFactory: sessionFactory, endpointType: endpointType)
    }

    func setUpPluginForSingleError(for endpointType: AWSAPICategoryPluginEndpointType) throws {
        let task = try makeSingleValueErrorMockTask()
        let mockSession = MockURLSession(onTaskForRequest: { _ in task })
        let sessionFactory = MockSessionFactory(returning: mockSession)
        try setUpPlugin(sessionFactory: sessionFactory, endpointType: endpointType)
    }

    func setUpPluginForSubscriptionResponse(
        onGetOrCreateConnection: @escaping MockSubscriptionConnectionFactory.OnGetOrCreateConnection
    ) throws {
        let subscriptionConnectionFactory = MockSubscriptionConnectionFactory(
            onGetOrCreateConnection: onGetOrCreateConnection
        )

        try setUpPlugin(
            subscriptionConnectionFactory: subscriptionConnectionFactory,
            endpointType: .graphQL
        )
    }

    func makeSingleValueSuccessMockTask(sending data: Data) throws -> MockURLSessionTask {
        var mockTask: MockURLSessionTask!
        mockTask = MockURLSessionTask(onResume: {
            guard let mockSession = mockTask.mockSession,
                let delegate = mockSession.sessionBehaviorDelegate
                else {
                    return
            }

            delegate.urlSessionBehavior(mockSession,
                                        dataTaskBehavior: mockTask,
                                        didReceive: data)

            delegate.urlSessionBehavior(mockSession,
                                        dataTaskBehavior: mockTask,
                                        didCompleteWithError: nil)
        })

        guard let task = mockTask else {
            throw "mockTask unexpectedly nil"
        }

        return task
    }

    func makeSingleValueErrorMockTask() throws -> MockURLSessionTask {
        var mockTask: MockURLSessionTask!
        mockTask = MockURLSessionTask(onResume: {
            guard let mockSession = mockTask.mockSession,
                let delegate = mockSession.sessionBehaviorDelegate
                else {
                    return
            }

            delegate.urlSessionBehavior(mockSession,
                                        dataTaskBehavior: mockTask,
                                        didCompleteWithError: URLError(.badServerResponse))
        })

        guard let task = mockTask else {
            throw "mockTask unexpectedly nil"
        }

        return task
    }

}
