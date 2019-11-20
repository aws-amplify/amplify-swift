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

    static let networkTimeout = TimeInterval(180)

    /* Instructions for `todoGraphQLWithUserPools`
     `amplify add api`
        * Please select from one of the below mentioned services GraphQL
        * Provide API name: api4
        * Choose the default authorization type for the API Amazon Cognito User Pool
     Using service: Cognito, provided by: awscloudformation

      The current configured provider is Amazon Cognito.

      Do you want to use the default authentication and security configuration? Default configuration
      Warning: you will not be able to edit these selections.
      How do you want users to be able to sign in? Email
      Do you want to configure advanced settings? No, I am done.
     Successfully added auth resource
        * Do you want to configure advanced settings for the GraphQL API `No, I am done.`
        * Do you have an annotated GraphQL schema? `No`
        * Do you want a guided schema creation? `Yes`
        * What best describes your project: `Single object with fields (e.g., “Todo” with ID, name, description)`
        * Do you want to edit the schema now? `No`
     */
    static let todoGraphQLWithUserPools = "todoGraphQLWithUserPools"

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

    override func setUp() {
        let config = [
            "CredentialsProvider": [
                "CognitoIdentity": [
                    "Default": [
                        "PoolId": "us-east-1:574af171-0ced-4b7b-8157-762cdd1ffffc",
                        "Region": "us-east-1"
                    ]
                ]
            ],
            "CognitoUserPool": [
                "Default": [
                    "PoolId": "us-east-1_6FWhDURBi",
                    "AppClientId": "1mptkb7veup5ujlqbngpcmg06d",
                    "AppClientSecret": "1qq2vo5rv9oc1th3bulsv8hlll8djqkc9on0j7d7gi4c8lfisoei",
                    "Region": "us-east-1"
                ]
            ]
        ]
        AWSInfo.configureDefaultAWSInfo(config)

        GraphQLWithUserPoolIntegrationTests.initializeMobileClient()

        Amplify.reset()
        let plugin = AWSAPICategoryPlugin()

        let apiConfig = APICategoryConfiguration(plugins: [
            "AWSAPICategoryPlugin": [
                GraphQLWithUserPoolIntegrationTests.todoGraphQLWithUserPools: [
                    "Endpoint": "https://ggp44fsi3fg5hhg5vq6r65a5wu.appsync-api.us-east-1.amazonaws.com/graphql",
                    "Region": "us-east-1",
                    "AuthorizationType": "AMAZON_COGNITO_USER_POOLS",
                    "EndpointType": "GraphQL"
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
        let request = GraphQLRequest(apiName: GraphQLWithUserPoolIntegrationTests.todoGraphQLWithUserPools,
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
        waitForExpectations(timeout: GraphQLWithUserPoolIntegrationTests.networkTimeout)
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
        let request = GraphQLRequest(apiName: GraphQLWithUserPoolIntegrationTests.todoGraphQLWithUserPools,
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
        waitForExpectations(timeout: GraphQLWithUserPoolIntegrationTests.networkTimeout)
    }

    func signIn(username: String, password: String) {
           let signInWasSuccessful = expectation(description: "signIn was successful")
           AWSMobileClient.sharedInstance().signIn(username: username, password: password) { result, error in
               if let error = error {
                   XCTFail("Sign in failed: \(error.localizedDescription)")
                   return
               }

               guard let result = result else {
                   XCTFail("No result from SignIn")
                   return
               }
               XCTAssertEqual(result.signInState, .signedIn)
               signInWasSuccessful.fulfill()
           }
           waitForExpectations(timeout: GraphQLWithUserPoolIntegrationTests.networkTimeout)
       }

    func signUpUser(username: String, password: String) {
        let signUpExpectation = expectation(description: "successful sign up expectation.")
        let userAttributes = ["email": username]
        AWSMobileClient.default().signUp(username: username, password: password, userAttributes: userAttributes) { result, error in

            if let error = error as? AWSMobileClientError {
                XCTFail("Failed to sign up user with error: \(error.message)")
                return
            }

            guard result != nil else {
                XCTFail("result from signUp should not be nil")
                return
            }

            signUpExpectation.fulfill()
        }

        waitForExpectations(timeout: GraphQLWithUserPoolIntegrationTests.networkTimeout)
    }

    static func initializeMobileClient() {
        let callbackInvoked = DispatchSemaphore(value: 1)

        AWSMobileClient.default().initialize { userState, error in
            if let error = error {
                XCTFail("Error initializing AWSMobileClient. Error: \(error.localizedDescription)")
                return
            }

            guard let userState = userState else {
                XCTFail("userState is unexpectedly empty initializing AWSMobileClient")
                return
            }

            if userState != UserState.signedOut {
                AWSMobileClient.default().signOut()
            }
            print("AWSMobileClient Initialized")
            callbackInvoked.signal()
        }

        _ = callbackInvoked.wait(timeout: .now() + 100)
    }

}
