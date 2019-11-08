//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import AWSMobileClient

class AWSAPICategoryPluginTodoGraphQLWithIAMTests: AWSAPICategoryPluginBaseTests {

    // MARK: set up
    /*
     we need to update AmplifyTestApp to use the right cognito which is set up with guest access

     this is working only because iam policy is set up correctly.

     {
     "UserAgent": "aws-amplify/cli",
     "Version": "0.1.0",
     "IdentityManager": {
         "Default": {}
     },
     "AppSync": {
         "Default": { // this is `todoGraphQLWithIAMWithGuestAccess`
             "ApiUrl": "https://fsdfgjw5ojdanhivobrnmw54s4.appsync-api.us-east-1.amazonaws.com/graphql",
             "Region": "us-east-1",
             "AuthMode": "AWS_IAM",
             "ClientDatabasePrefix": "api3_AWS_IAM"
         }
     },
     "CredentialsProvider": {
         "CognitoIdentity": {
             "Default": {
                 "PoolId": "us-east-1:35d7a505-675c-440e-969f-82d0773b586b",
                 "Region": "us-east-1"
             }
         }
     },
     "CognitoUserPool": {
         "Default": {
             "PoolId": "us-east-1_PdSfW6IgE",
             "AppClientId": "5gf44rm3rv8ar0o9spcuols1g4",
             "AppClientSecret": "11343jpcqhj7dqvacjkq5hlrcrlauqka56jg7lhi00vq1ra1b57i",
             "Region": "us-east-1"
         }
     }
     */
    let user1 = "storageUser1@testing.com"
    let user2  = "storageUser2@testing.com"
    let password = "Abc123@@!!"
    // This is a run once function to set up users then use console to verify and run rest of these tests.
    func testSetUpOnce() {
        signUpUser(username: user1, password: password)
        signUpUser(username: user2, password: password)
    }

    /// Given: A CreateTodo mutation request, and user is signed in.
    /// When: Call mutate API
    /// Then: The operation completes successfully with no errors and todo in response
    func testCreateTodoMutationWithIAMWithGuestAccessCompletesSuccessfully() {
        signIn(username: user1, password: password)
        let completeInvoked = expectation(description: "request completed")

        let expectedId = UUID().uuidString
        let expectedName = "testCreateTodoMutationName"
        let expectedDescription = "testCreateTodoMutationDescription"
        let operation = Amplify.API.mutate(apiName: IntegrationTestConfiguration.todoGraphQLWithIAM,
                                           document: CreateTodoMutation.document,
                                           variables: CreateTodoMutation.variables(id: expectedId,
                                                                                   name: expectedName,
                                                                                   description: expectedDescription),
                                           responseType: CreateTodoMutation.Data.self) { (event) in
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
        waitForExpectations(timeout: AWSAPICategoryPluginBaseTests.networkTimeout)
    }

    /// Given: A CreateTodo mutation request, and no user signed in
    /// When: Call mutate API
    /// Then: The operation fails and contains UnAuthorized error
    func testCreateTodoMutationWithIAMWithNoUserSignedIn() {
        let failedInvoked = expectation(description: "request failed")

        let expectedId = UUID().uuidString
        let expectedName = "testCreateTodoMutationName"
        let expectedDescription = "testCreateTodoMutationDescription"
        let operation = Amplify.API.mutate(apiName: IntegrationTestConfiguration.todoGraphQLWithIAM,
                                           document: CreateTodoMutation.document,
                                           variables: CreateTodoMutation.variables(id: expectedId,
                                                                                   name: expectedName,
                                                                                   description: expectedDescription),
                                           responseType: CreateTodoMutation.Data.self) { (event) in
            switch event {
            case .completed(let graphQLResponse):
                XCTFail("Unexpected .completed event: \(graphQLResponse)")
            case .failed(let error):
                print(error)
                failedInvoked.fulfill()
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: AWSAPICategoryPluginBaseTests.networkTimeout)
    }
}
