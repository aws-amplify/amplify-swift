//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSAPICategoryPlugin
@testable import AWSAPICategoryPluginTestCommon

class GraphQLWithIAMIntegrationTests: XCTestCase {

    let user1 = "user1@GraphQLWithIAMIntegrationTests.com"
    let password = "Abc123@@!!"

    override func setUp() {
        let config = [
            "CredentialsProvider": [
                "CognitoIdentity": [
                    "Default": [
                        "PoolId": "us-east-1:xxxx",
                        "Region": "us-east-1"
                    ]
                ]
            ],
            "CognitoUserPool": [
                "Default": [
                    "PoolId": "us-east-1_xxx",
                    "AppClientId": "xxxx",
                    "AppClientSecret": "xxxx",
                    "Region": "us-east-1"
                ]
            ]
        ]
        AWSInfo.configureDefaultAWSInfo(config)

        AuthHelper.initializeMobileClient()

        Amplify.reset()
        let plugin = AWSAPIPlugin()

        let apiConfig = APICategoryConfiguration(plugins: [
            "awsAPIPlugin": [
                "todoGraphQLWithIAM": [
                    "endpoint": "https://xxxx.appsync-api.us-east-1.amazonaws.com/graphql",
                    "region": "us-east-1",
                    "authorizationType": "AWS_IAM",
                    "endpointType": "GraphQL"
                ]
            ]
        ])

        let amplifyConfig = AmplifyConfiguration(api: apiConfig)
        do {
            try Amplify.add(plugin: plugin)
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func tearDown() {
        Amplify.reset()
    }

    // This is a run once function to set up users then use console to verify and run rest of these tests.
    func testSetUpOnce() {
        AuthHelper.signUpUser(username: user1, password: password)
    }

    /// Given: A CreateTodo mutation request, and user is signed in.
    /// When: Call mutate API
    /// Then: The operation completes successfully with no errors and todo in response
    func testCreateTodoMutationWithIAMWithGuestAccessCompletesSuccessfully() {
        AuthHelper.signIn(username: user1, password: password)
        let completeInvoked = expectation(description: "request completed")

        let expectedId = UUID().uuidString
        let expectedName = "testCreateTodoMutationName"
        let expectedDescription = "testCreateTodoMutationDescription"
        let request = GraphQLRequest(apiName: "todoGraphQLWithIAM",
                                     document: CreateTodoMutation.document,
                                     variables: CreateTodoMutation.variables(id: expectedId,
                                                                             name: expectedName,
                                                                             description: expectedDescription),
                                     responseType: CreateTodoMutation.Data.self)
        let operation = Amplify.API.mutate(request: request) { event in
            switch event {
            case .completed(let graphQLResponse):
                guard case let .success(data) = graphQLResponse else {
                    XCTFail("Missing successful response")
                    return
                }
                guard let todo = data.createTodo else {
                    XCTFail("Missing Todo")
                    return
                }

                XCTAssertEqual(todo.id, expectedId)
                XCTAssertEqual(todo.name, expectedName)
                XCTAssertEqual(todo.description, expectedDescription)
                XCTAssertEqual(todo.typename, String(describing: Todo.self))

                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Unexpected .failed event: \(error)")
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    /// Given: A CreateTodo mutation request, and no user signed in
    /// When: Call mutate API
    /// Then: The operation fails and contains UnAuthorized error
    func testCreateTodoMutationWithIAMWithNoUserSignedIn() {
        let failedInvoked = expectation(description: "request failed")
        let expectedId = UUID().uuidString
        let expectedName = "testCreateTodoMutationName"
        let expectedDescription = "testCreateTodoMutationDescription"
        let request = GraphQLRequest(apiName: "todoGraphQLWithIAM",
                                     document: CreateTodoMutation.document,
                                     variables: CreateTodoMutation.variables(id: expectedId,
                                                                             name: expectedName,
                                                                             description: expectedDescription),
                                     responseType: CreateTodoMutation.Data.self)
        let operation = Amplify.API.mutate(request: request) { event in
            switch event {
            case .completed(let result):
                XCTFail("Unexpected .completed event: \(result)")
            case .failed(let error):
                print(error)
                guard case let .httpStatusError(statusCode, _) = error else {
                    XCTFail("Should be HttpStatusError")
                    return
                }

                XCTAssertEqual(statusCode, 401)
                failedInvoked.fulfill()
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }
}
