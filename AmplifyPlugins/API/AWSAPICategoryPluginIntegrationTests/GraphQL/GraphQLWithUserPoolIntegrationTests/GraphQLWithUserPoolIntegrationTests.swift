//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
import AWSMobileClient
import AWSAPICategoryPlugin
@testable import AWSAPICategoryPluginTestCommon

class GraphQLWithUserPoolIntegrationTests: XCTestCase {

    static let amplifyConfiguration = "GraphQLWithUserPoolIntegrationTests-amplifyconfiguration"
    static let awsconfiguration = "GraphQLWithUserPoolIntegrationTests-awsconfiguration"

    override func setUp() {
        do {
            let awsConfiguration = try TestConfigHelper.retrieveAWSConfiguration(
                forResource: GraphQLWithUserPoolIntegrationTests.awsconfiguration)
            AWSInfo.configureDefaultAWSInfo(awsConfiguration)

            AuthHelper.initializeMobileClient()

            Amplify.reset()

            try Amplify.add(plugin: AWSAPIPlugin())

            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(
                forResource: GraphQLWithUserPoolIntegrationTests.amplifyConfiguration)
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func tearDown() {
        Amplify.reset()
    }

    let user1 = "user1@GraphQLWithUserPoolIntegrationTests.com"
    let password = "Abc123@@!!"
    // This is a run once function to set up users then use console to verify and run rest of these tests.
    func testSetUpOnce() {
        AuthHelper.signUpUser(username: user1, password: password)
    }

    /// Given: A CreateTodo mutation request, and user signed in, graphql has userpools as auth mode.
    /// When: Call mutate API
    /// Then: The operation completes successfully with no errors and todo in response
    func testCreateTodoMutationWithUserPoolWithSignedInUser() {
        AuthHelper.signIn(username: user1, password: password)
        let completeInvoked = expectation(description: "request completed")
        let expectedId = UUID().uuidString
        let expectedName = "testCreateTodoMutationName"
        let expectedDescription = "testCreateTodoMutationDescription"
        let request = GraphQLRequest(document: CreateTodoMutation.document,
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

    /// Given: GraphQL with userPool, no user signed in, Cognito configured with no guest access.
    /// When: Call mutate API
    /// Then: The operation fails with error, user not signed in.
    func testCreateTodoMutationWithUserPoolWithoutSignedInUserFailsWithError() {
        AWSMobileClient.default().signOut()
        let failedInvoked = expectation(description: "request failed")
        let expectedId = UUID().uuidString
        let expectedName = "testCreateTodoMutationName"
        let expectedDescription = "testCreateTodoMutationDescription"
        let request = GraphQLRequest(document: CreateTodoMutation.document,
                                     variables: CreateTodoMutation.variables(id: expectedId,
                                                                             name: expectedName,
                                                                             description: expectedDescription),
                                     responseType: CreateTodoMutation.Data.self)
        let operation = Amplify.API.mutate(request: request) { event in
            switch event {
            case .completed(let graphQLResponse):
                XCTFail("Unexpected .completed event: \(graphQLResponse)")
            case .failed(let error):

                print("Got error back because user not signed in: \(error)")
                failedInvoked.fulfill()
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }
}
