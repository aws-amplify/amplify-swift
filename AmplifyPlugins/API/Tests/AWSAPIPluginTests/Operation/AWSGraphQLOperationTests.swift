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
import AWSPluginsCore

class AWSGraphQLOperationTests: AWSAPICategoryPluginTestBase {

    /// Tests that upon completion, the operation is removed from the task mapper.
    func testOperationCleanup() async {
        let request = GraphQLRequest(apiName: apiName,
                                     document: testDocument,
                                     variables: nil,
                                     responseType: JSONValue.self)

        let operation = apiPlugin.query(request: request, listener: nil)

        guard let operation = operation as? AWSGraphQLOperation else {
            XCTFail("Operation is not an AWSGraphQLOperation")
            return
        }

        let receivedCompletion = expectation(description: "Received completion")
        let sink = operation.resultPublisher.sink { _ in
            receivedCompletion.fulfill()
        } receiveValue: { _ in }
        defer { sink.cancel() }

        await fulfillment(of: [receivedCompletion], timeout: 1)
        let task = operation.mapper.task(for: operation)
        XCTAssertNil(task)
    }


    /// Request for `.amazonCognitoUserPool` at runtime with `request` while passing in what
    /// is configured as `.apiKey`. Expect that the interceptor is the token interceptor
    func testGetEndpointInterceptors() throws {
        let request = GraphQLRequest<JSONValue>(apiName: apiName,
                                                document: testDocument,
                                                variables: nil,
                                                responseType: JSONValue.self,
                                                authMode: AWSAuthorizationType.amazonCognitoUserPools)
        let task = try OperationTestBase.makeSingleValueErrorMockTask()
        let mockSession = MockURLSession(onTaskForRequest: { _ in task })
        let pluginConfig = AWSAPICategoryPluginConfiguration(
            endpoints: [
                apiName: try .init(
                    name: apiName,
                    baseURL: URL(string: "url")!,
                    region: "us-test-1",
                    authorizationType: .apiKey,
                    endpointType: .graphQL,
                    apiKey: "apiKey",
                    apiAuthProviderFactory: .init())],
            apiAuthProviderFactory: .init(),
            authService: MockAWSAuthService())
        let operation = AWSGraphQLOperation(request: request.toOperationRequest(operationType: .query),
                                            session: mockSession,
                                            mapper: OperationTaskMapper(),
                                            pluginConfig: pluginConfig,
                                            resultListener: { _ in })

        // Act
        let results = operation.getEndpointInterceptors()

        // Assert
        guard case let .success(interceptors) = results,
              let interceptor = interceptors?.preludeInterceptors.first,
              (interceptor as? AuthTokenURLRequestInterceptor) != nil else {
            XCTFail("Should be token interceptor for Cognito User Pool")
            return
        }
    }
}
