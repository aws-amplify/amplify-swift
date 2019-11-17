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

class GraphQLWithIAMIntegrationTests: XCTestCase {

   static let networkTimeout = TimeInterval(180)


    // MARK: set up
    /*
    These instructions for `todoGraphQLWithIAM` is to set up the GraphQL appsync endpoint with
    - Default authorization mode to be "AWS Identity and Access Management (IAM)"
    - Cognito identity pool with no guess access
    === WARNING: this is not working without setting IAM policy to allow GraphQL operations ===

    1. Run `amplify init` and choose `ios` for the type of app you're building

    2. Add api `amplify add api`
        * Please select from one of the below mentioned services `GraphQL`
        * Provide API name: `temp123`
        * Choose the default authorization type for the API `IAM`
        * Do you want to configure advanced settings for the GraphQL API `No, I am done.`
        * Do you have an annotated GraphQL schema? `No`
        * Do you want a guided schema creation? `Yes`
        * What best describes your project: `Objects with fine-grained access control (e.g., a project management app
           with owner-based authorization)`
        * Do you want to edit the schema now? `No`

    3. Add Auth `amplify add auth`
    Using service: Cognito, provided by: awscloudformation

     The current configured provider is Amazon Cognito.

     Do you want to use the default authentication and security configuration? `Default configuration`
     Warning: you will not be able to edit these selections.
     How do you want users to be able to sign in? Username
     Do you want to configure advanced settings? `No, I am done.`
    Successfully added resource appsyncsample6b51ebcc locally

    4. `amplify push`
       * Do you want to generate code for your newly created GraphQL API `Yes`
       * Enter the file name pattern of graphql queries, mutations and subscriptions `graphql/**/*.graphql`
       * Do you want to generate/update all possible GraphQL operations - queries, mutations and subscriptions `Yes`
       * Enter maximum statement depth [increase from default if your schema is deeply nested] `2`
       * Enter the file name for the generated code `API.swift`
       * GraphQL endpoint: `https://szc4yxxxxxxxxxxqaaiwoqe.appsync-api.us-east-1.amazonaws.com/graphql`

    5. Update the IAMPolicy to allow operations on the GraphQL service
     TODO: Fix these instructions
    */

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

    override func setUp() {
        let config = [
            "CredentialsProvider": [
                "CognitoIdentity": [
                    "Default": [
                        "PoolId": "us-east-1:35d7a505-675c-440e-969f-82d0773b586b",
                        "Region": "us-east-1"
                    ]
                ]
            ],
            "CognitoUserPool": [
                "Default": [
                    "PoolId": "us-east-1_PdSfW6IgE",
                    "AppClientId": "5gf44rm3rv8ar0o9spcuols1g4",
                    "AppClientSecret": "11343jpcqhj7dqvacjkq5hlrcrlauqka56jg7lhi00vq1ra1b57i",
                    "Region": "us-east-1"
                ]
            ]
        ]
        AWSInfo.configureDefaultAWSInfo(config)

        GraphQLWithIAMIntegrationTests.initializeMobileClient()

        Amplify.reset()
        let plugin = AWSAPICategoryPlugin()

        let apiConfig = APICategoryConfiguration(plugins: [
            "AWSAPICategoryPlugin": [
                "todoGraphQLWithIAM": [
                    "Endpoint": "https://fsdfgjw5ojdanhivobrnmw54s4.appsync-api.us-east-1.amazonaws.com/graphql",
                    "Region": "us-east-1",
                    "AuthorizationType": "AWS_IAM",
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
        waitForExpectations(timeout: GraphQLWithIAMIntegrationTests.networkTimeout)
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
                switch result {
                case .error(let errors):
                    print(errors)
                    failedInvoked.fulfill()
                default:
                    XCTFail("Unexpected event: \(event)")
                }
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: GraphQLWithIAMIntegrationTests.networkTimeout)
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
           waitForExpectations(timeout: GraphQLWithIAMIntegrationTests.networkTimeout)
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

        waitForExpectations(timeout: GraphQLWithIAMIntegrationTests.networkTimeout)
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
