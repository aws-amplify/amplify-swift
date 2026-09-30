//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSAPIPlugin
@testable import AWSPluginsTestCommon

/// - Note: `@unchecked Sendable` so subclass test bodies can be captured by the `@Sendable` closures
///   `Amplify.Publisher.create` takes. `XCTestCase` is not `Sendable`, and each test runs alone.
class OperationTestBase: XCTestCase, @unchecked Sendable {

    var apiPlugin: AWSAPIPlugin!

    override func setUp() async throws {
        if apiPlugin != nil {
            await apiPlugin.reset()
        }
        apiPlugin = nil
    }

    func setUpPlugin(
        sessionFactory: URLSessionBehaviorFactory? = nil,
        appSyncRealTimeClientFactory: AppSyncRealTimeClientFactoryProtocol? = nil,
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
            appSyncRealTimeClientFactory: appSyncRealTimeClientFactory
        )

        apiPlugin.configure(using: dependencies)
    }

    func setUpPluginForSingleResponse(
        sending data: Data,
        for endpointType: AWSAPICategoryPluginEndpointType
    ) throws {
        let task = makeSingleValueSuccessMockTask(sending: data)
        let mockSession = MockURLSession(onTaskForRequest: { _ in task })
        let sessionFactory = MockSessionFactory(returning: mockSession)
        try setUpPlugin(sessionFactory: sessionFactory, endpointType: endpointType)
    }

    func setUpPluginForSingleError(for endpointType: AWSAPICategoryPluginEndpointType) throws {
        let task = Self.makeSingleValueErrorMockTask()
        let mockSession = MockURLSession(onTaskForRequest: { _ in task })
        let sessionFactory = MockSessionFactory(returning: mockSession)
        try setUpPlugin(sessionFactory: sessionFactory, endpointType: endpointType)
    }

    func setUpPluginForSubscriptionResponse(
        onGetOrCreateConnection: @escaping MockSubscriptionConnectionFactory.OnGetOrCreateConnection
    ) throws {

        let appSyncRealTimeClientFactory = MockSubscriptionConnectionFactory(onGetOrCreateConnection: onGetOrCreateConnection)

        try setUpPlugin(
            appSyncRealTimeClientFactory: appSyncRealTimeClientFactory,
            endpointType: .graphQL
        )
    }

    func makeSingleValueSuccessMockTask(sending data: Data) -> MockURLSessionTask {
        // The `onResume` closure has to reference the task it is being assigned to, so the task is
        // held in an `AtomicValue`: capturing the `var` directly is a reference to a mutable variable
        // from concurrently-executing code, which the Swift 6 language mode rejects.
        let mockTaskBox = AtomicValue<MockURLSessionTask?>(initialValue: nil)
        let mockTask = MockURLSessionTask(onResume: {
            guard let mockTask = mockTaskBox.get() else { return }
            guard let mockSession = mockTask.mockSession,
                let delegate = mockSession.sessionBehaviorDelegate
                else {
                    return
            }

            delegate.urlSessionBehavior(
                mockSession,
                dataTaskBehavior: mockTask,
                didReceive: data
            )

            delegate.urlSessionBehavior(
                mockSession,
                dataTaskBehavior: mockTask,
                didCompleteWithError: nil
            )
        })

        mockTaskBox.set(mockTask)
        return mockTask
    }

    static func makeSingleValueErrorMockTask() -> MockURLSessionTask {
        // The `onResume` closure has to reference the task it is being assigned to, so the task is
        // held in an `AtomicValue`: capturing the `var` directly is a reference to a mutable variable
        // from concurrently-executing code, which the Swift 6 language mode rejects.
        let mockTaskBox = AtomicValue<MockURLSessionTask?>(initialValue: nil)
        let mockTask = MockURLSessionTask(onResume: {
            guard let mockTask = mockTaskBox.get() else { return }
            guard let mockSession = mockTask.mockSession,
                let delegate = mockSession.sessionBehaviorDelegate
                else {
                    return
            }

            delegate.urlSessionBehavior(
                mockSession,
                dataTaskBehavior: mockTask,
                didCompleteWithError: URLError(.badServerResponse)
            )
        })

        mockTaskBox.set(mockTask)
        return mockTask
    }

}
