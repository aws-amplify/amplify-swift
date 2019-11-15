//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Amplify
import AWSMobileClient

class AWSAPICategoryPluginTodoGraphQLWithUserPoolTests: AWSAPICategoryPluginBaseTests {

    /*
     Make sure to override AmplifyTestApp's with this cognitoUserPool/CrdentialsProvider
     {
         "UserAgent": "aws-amplify/cli",
         "Version": "0.1.0",
         "IdentityManager": {
             "Default": {}
         },
         "CredentialsProvider": {
             "CognitoIdentity": {
                 "Default": {
                     "PoolId": "us-east-1:574af171-0ced-4b7b-8157-762cdd1ffffc",
                     "Region": "us-east-1"
                 }
             }
         },
         "CognitoUserPool": {
             "Default": {
                 "PoolId": "us-east-1_6FWhDURBi",
                 "AppClientId": "1mptkb7veup5ujlqbngpcmg06d",
                 "AppClientSecret": "1qq2vo5rv9oc1th3bulsv8hlll8djqkc9on0j7d7gi4c8lfisoei",
                 "Region": "us-east-1"
             }
         },
         "AppSync": {
             "Default": {
                 "ApiUrl": "https://ggp44fsi3fg5hhg5vq6r65a5wu.appsync-api.us-east-1.amazonaws.com/graphql",
                 "Region": "us-east-1",
                 "AuthMode": "AMAZON_COGNITO_USER_POOLS",
                 "ClientDatabasePrefix": "api4_AMAZON_COGNITO_USER_POOLS"
             }
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

    /// Given: A CreateTodo mutation request, and user signed in, graphql has userpools as auth mode.
    /// When: Call mutate API
    /// Then: The operation completes successfully with no errors and todo in response
    func testCreateTodoMutationWithUserPoolWithSignedInUser() {
        signIn(username: user1, password: password)
        let completeInvoked = expectation(description: "request completed")
        let expectedId = UUID().uuidString
        let expectedName = "testCreateTodoMutationName"
        let expectedDescription = "testCreateTodoMutationDescription"
        let request = GraphQLRequest(apiName: IntegrationTestConfiguration.todoGraphQLWithUserPools,
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
        waitForExpectations(timeout: AWSAPICategoryPluginBaseTests.networkTimeout)
    }

    /// Given: GraphQL with userPool, no user signed in, Cognito configured with no guest access.
    /// When: Call mutate API
    /// Then: The operation fails with error, user not signed in.
    func testCreateTodoMutationWithIAMWithoutGuestAccessFailWithError() {
        AWSMobileClient.default().signOut()
        let failedInvoked = expectation(description: "request failed")
        let expectedId = UUID().uuidString
        let expectedName = "testCreateTodoMutationName"
        let expectedDescription = "testCreateTodoMutationDescription"
        let request = GraphQLRequest(apiName: IntegrationTestConfiguration.todoGraphQLWithUserPools,
                                     document: CreateTodoMutation.document,
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
        waitForExpectations(timeout: AWSAPICategoryPluginBaseTests.networkTimeout)
    }
}
