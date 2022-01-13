//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSPluginsCore
import AWSAPIPlugin
import AWSCognitoAuthPlugin

@testable import Amplify
@testable import AmplifyTestCommon

class GraphQLWithIAMIntegrationTests: XCTestCase {

    let amplifyConfigurationFile = "GraphQLWithIAMIntegrationTests-amplifyconfiguration"
    let credentialsFile = "GraphQLWithIAMIntegrationTests-credentials"
    var user: User!

    enum TestConfigError: Error {
        
        case jsonError(String)
        
        case bundlePathError(String)
    }
    
    static func retrieveCredentials(forResource: String) throws -> [String: String] {
        guard let url = Bundle.module.url(forResource: forResource, withExtension: "json") else {
            throw "Could not retrieve configuration file: \(forResource)"
        }
        
        let data = try Data(contentsOf: url)
        
        let jsonOptional = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String]
        guard let json = jsonOptional else {
            throw TestConfigError.jsonError("Could not deserialize `\(forResource)` into JSON object")
        }
        
        return json
    }
    
    static func retrieveAmplifyConfiguration(forResource: String) throws -> AmplifyConfiguration {

        guard let url = Bundle.module.url(forResource: forResource, withExtension: "json") else {
            throw "Could not retrieve configuration file: \(forResource)"
        }
        let data = try Data(contentsOf: url)
        return try AmplifyConfiguration.decodeAmplifyConfiguration(from: data)
    }

    override func setUp() {
        do {
            let credentials = try GraphQLWithIAMIntegrationTests.retrieveCredentials(forResource: credentialsFile)

            guard let username = credentials["username"],
                  let password = credentials["password"] else {
                XCTFail("Missing credentials.json data")
                return
            }

            user = User(username: username, password: password)

            try Amplify.add(plugin: AWSAPIPlugin())
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            let amplifyConfig = try GraphQLWithIAMIntegrationTests.retrieveAmplifyConfiguration(forResource: amplifyConfigurationFile)
            try Amplify.configure(amplifyConfig)

            ModelRegistry.register(modelType: Todo.self)
        } catch {
            XCTFail("Error during setup: \(error)")
        }
        // TODO: uncomment this once signIn works
//        if isSignedIn() {
//            signOut()
//        }
    }

    override func tearDown() {
        Amplify.reset()
    }

    /// Test create mutation with a custom GraphQL Document
    ///
    /// - Given:  A custom GraphQL document containing CreateTodo mutation request, and user is signed in.
    /// - When:
    ///    - Call mutate API
    /// - Then:
    ///    - The operation completes successfully with no errors and todo in response
    ///
    func testCreateTodoMutationWithCustomGraphQLDocument() {
        registerAndSignIn()
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
            case .success(let graphQLResponse):
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
            case .failure(let error):
                XCTFail("Unexpected .failed event: \(error)")
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    /// An unauthenticated user should not fail
    ///
    /// - Given:  A CreateTodo mutation request, and user is not signed in.
    /// - When:
    ///    - Call mutate API
    /// - Then:
    ///    - The operation fails and contains http status error for 401 (Unauthorized)
    ///
    func testCreateTodoMutationWithIAMWithNoUserSignedIn() {
        let successInvoked = expectation(description: "request failed")
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
            case .success(let result):
                print(result)
                successInvoked.fulfill()
            case .failure(let error):
                print(error)
                if case let .httpStatusError(statusCode, response) = error,
                    let awsResponse = response as? AWSHTTPURLResponse,
                    let responseBody = awsResponse.body
                {
                    print("Response contains a \(responseBody.count) byte long response body")
                }
                XCTFail("Failed with error \(error)")
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    /// A subscription to onCreate todo should receive an event for each create Todo mutation API called. User is not signed in
    ///
    /// - Given:  An onCreate Todo subscription established
    /// - When:
    ///    - Create todo mutations API called
    /// - Then:
    ///    - The subscription should receive mutation events corresponding to the API calls performed.
    ///
    func testOnCreateTodoUnauthRole() {
        // signIn(username: user.username, password: user.password)
        let connectedInvoked = expectation(description: "Connection established")
        let disconnectedInvoked = expectation(description: "Connection disconnected")
        let completedInvoked = expectation(description: "Completed invoked")
        let progressInvoked = expectation(description: "progress invoked")
        progressInvoked.expectedFulfillmentCount = 2
        let uuid = UUID().uuidString
        let uuid2 = UUID().uuidString
        let name = String("\(#function)".dropLast(2))

        let operation = Amplify.API.subscribe(
            request: .subscription(of: Todo.self, type: .onCreate),
            valueListener: { event in
                switch event {
                case .connection(let state):
                    switch state {
                    case .connecting:
                        break
                    case .connected:
                        connectedInvoked.fulfill()
                    case .disconnected:
                        disconnectedInvoked.fulfill()
                    }
                case .data(let result):
                    switch result {
                    case .success(let todo):
                        if todo.id == uuid || todo.id == uuid2 {
                            progressInvoked.fulfill()
                        }
                    case .failure(let error):
                        XCTFail("\(error)")
                    }
                }

            },
            completionListener: { event in
                switch event {
                case .failure(let error):
                    XCTFail("Unexpected .failed event: \(error)")
                case .success:
                    completedInvoked.fulfill()
                }
            })

        XCTAssertNotNil(operation)
        wait(for: [connectedInvoked], timeout: TestCommonConstants.networkTimeout)

        guard createTodo(id: uuid, name: name) != nil,
              createTodo(id: uuid2, name: name) != nil else {
            XCTFail("Failed to create post")
            return
        }

        wait(for: [progressInvoked], timeout: TestCommonConstants.networkTimeout)
        operation.cancel()
        wait(for: [disconnectedInvoked, completedInvoked], timeout: TestCommonConstants.networkTimeout)
        XCTAssertTrue(operation.isFinished)
    }
    
    /// A subscription to onCreate todo should receive an event for each create Todo mutation API called
    ///
    /// - Given:  An onCreate Todo subscription established
    /// - When:
    ///    - Create todo mutations API called
    /// - Then:
    ///    - The subscription should receive mutation events corresponding to the API calls performed.
    ///
    func testOnCreateTodo() {
        registerAndSignIn()
        let connectedInvoked = expectation(description: "Connection established")
        let disconnectedInvoked = expectation(description: "Connection disconnected")
        let completedInvoked = expectation(description: "Completed invoked")
        let progressInvoked = expectation(description: "progress invoked")
        progressInvoked.expectedFulfillmentCount = 2
        let uuid = UUID().uuidString
        let uuid2 = UUID().uuidString
        let name = String("\(#function)".dropLast(2))

        let operation = Amplify.API.subscribe(
            request: .subscription(of: Todo.self, type: .onCreate),
            valueListener: { event in
                switch event {
                case .connection(let state):
                    switch state {
                    case .connecting:
                        break
                    case .connected:
                        connectedInvoked.fulfill()
                    case .disconnected:
                        disconnectedInvoked.fulfill()
                    }
                case .data(let result):
                    switch result {
                    case .success(let todo):
                        if todo.id == uuid || todo.id == uuid2 {
                            progressInvoked.fulfill()
                        }
                    case .failure(let error):
                        XCTFail("\(error)")
                    }
                }

            },
            completionListener: { event in
                switch event {
                case .failure(let error):
                    XCTFail("Unexpected .failed event: \(error)")
                case .success:
                    completedInvoked.fulfill()
                }
            })

        XCTAssertNotNil(operation)
        wait(for: [connectedInvoked], timeout: TestCommonConstants.networkTimeout)

        guard createTodo(id: uuid, name: name) != nil,
              createTodo(id: uuid2, name: name) != nil else {
            XCTFail("Failed to create post")
            return
        }

        wait(for: [progressInvoked], timeout: TestCommonConstants.networkTimeout)
        operation.cancel()
        wait(for: [disconnectedInvoked, completedInvoked], timeout: TestCommonConstants.networkTimeout)
        XCTAssertTrue(operation.isFinished)
    }

    // MARK: - Helpers

    func registerAndSignIn() {
        let registerAndSignInComplete = expectation(description: "register and sign in completed")
        AuthSignInHelper.registerAndSignInUser(username: username,
                                               password: password,
                                               email: email) { didSucceed, error in
            if didSucceed {
                registerAndSignInComplete.fulfill()
            } else {
                XCTFail("Failed to Sign in user \(error)")
            }
        }
        wait(for: [registerAndSignInComplete], timeout: TestCommonConstants.networkTimeout)
    }

    func isSignedIn() -> Bool {
        let checkIsSignedInCompleted = expectation(description: "retrieve auth session completed")
        var resultOptional: Bool?
        _ = Amplify.Auth.fetchAuthSession { event in
            switch event {
            case .success(let authSession):
                resultOptional = authSession.isSignedIn
                checkIsSignedInCompleted.fulfill()
            case .failure(let error):
                fatalError("Failed to get auth session \(error)")
            }
        }
        wait(for: [checkIsSignedInCompleted], timeout: TestCommonConstants.networkTimeout)
        guard let result = resultOptional else {
            fatalError("Could not get isSignedIn for user")
        }

        return result
    }

    func signOut() {
        let signOutCompleted = expectation(description: "sign out completed")
        _ = Amplify.Auth.signOut { event in
            switch event {
            case .success:
                signOutCompleted.fulfill()
            case .failure(let error):
                print("Could not sign out user \(error)")
                signOutCompleted.fulfill()
            }
        }
        wait(for: [signOutCompleted], timeout: TestCommonConstants.networkTimeout)
    }

    func createTodo(id: String, name: String) -> Todo? {
        let todo = Todo(id: id, name: name)
        var result: Todo?
        let requestInvokedSuccessfully = expectation(description: "request completed")

        _ = Amplify.API.mutate(request: .create(todo)) { event in
            switch event {
            case .success(let data):
                switch data {
                case .success(let post):
                    result = post
                default:
                    XCTFail("Create Post was not successful: \(data)")
                }
                requestInvokedSuccessfully.fulfill()
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [requestInvokedSuccessfully], timeout: TestCommonConstants.networkTimeout)
        return result
    }

    // MARK: - Model

    struct Todo: Model {
        public let id: String
        public var name: String
        public var description: String?

        init(id: String = UUID().uuidString,
             name: String,
             description: String? = nil) {
            self.id = id
            self.name = name
            self.description = description
        }

        enum CodingKeys: String, ModelKey {
            case id
            case name
            case description
        }

        static let keys = CodingKeys.self

        static let schema = defineSchema { model in
            let todo = Todo.keys

            model.listPluralName = "Todos"
            model.syncPluralName = "Todos"

            model.fields(
                .id(),
                .field(todo.name, is: .required, ofType: .string),
                .field(todo.description, is: .optional, ofType: .string)
            )
        }
    }
}
