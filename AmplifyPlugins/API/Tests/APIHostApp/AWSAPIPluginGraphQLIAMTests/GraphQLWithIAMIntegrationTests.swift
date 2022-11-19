//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSAPIPlugin
import AWSCognitoAuthPlugin

@testable import Amplify
@testable import APIHostApp
import Combine

class GraphQLWithIAMIntegrationTests: XCTestCase {

    let amplifyConfigurationFile = "testconfiguration/GraphQLWithIAMIntegrationTests-amplifyconfiguration"

    let username = "integTest\(UUID().uuidString)"
    let password = "P123@\(UUID().uuidString)"

    override func setUp() async throws {
        do {
            Amplify.Logging.logLevel = .verbose
            try Amplify.add(plugin: AWSAPIPlugin())
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: amplifyConfigurationFile)
            try Amplify.configure(amplifyConfig)

            ModelRegistry.register(modelType: Todo.self)
        } catch {
            XCTFail("Error during setup: \(error)")
        }
        
    }

    override func tearDown() async throws {
        if try await isSignedIn() {
            await signOut()
        }
        await Amplify.reset()
    }
        
    func testSignUserOut() async throws {
        if try await isSignedIn() {
            print("User is signed in")
        }

        await signOut()
    }
    
    /// Test create mutation with a custom GraphQL Document
    ///
    /// - Given:  A custom GraphQL document containing CreateTodo mutation request, and user is signed in.
    /// - When:
    ///    - Call mutate API
    /// - Then:
    ///    - The operation completes successfully with no errors and todo in response
    ///
    func testCreateTodoAuthRole() async throws {
        try await createAuthenticatedUser()
        try await createTodoTest()
    }
    
    /// An unauthenticated user should not fail
    ///
    /// - Given:  A CreateTodo mutation request, and user is not signed in.
    /// - When:
    ///    - Call mutate API
    /// - Then:
    ///    - The operation completes successfully with no errors and todo in response
    ///
    func testCreateTodoUnauthRole() async throws {
        if try await isSignedIn() {
            await signOut()
        }
        try await createTodoTest()
    }
    
    func createTodoTest() async throws {
        let expectedId = UUID().uuidString
        let expectedName = "testCreateTodoMutationName"
        let expectedDescription = "testCreateTodoMutationDescription"
        let request = GraphQLRequest(document: CreateTodoMutation.document,
                                     variables: CreateTodoMutation.variables(id: expectedId,
                                                                             name: expectedName,
                                                                             description: expectedDescription),
                                     responseType: CreateTodoMutation.Data.self)
        
        
        let event = try await Amplify.API.mutate(request: request)
        switch event {
        case .success(let data):
            guard let todo = data.createTodo else {
                XCTFail("Missing Todo")
                return
            }

            XCTAssertEqual(todo.id, expectedId)
            XCTAssertEqual(todo.name, expectedName)
            XCTAssertEqual(todo.description, expectedDescription)
            XCTAssertEqual(todo.typename, String(describing: Todo.self))

        case .failure(let error):
            XCTFail("Unexpected .failed event: \(error)")
        }
    }

    /// A subscription to onCreate todo should receive an event for each create Todo mutation API called. User is not signed in
    ///
    /// - Given:  An onCreate Todo subscription established
    /// - When:
    ///    - Create todo mutations API called
    /// - Then:
    ///    - The subscription should receive mutation events corresponding to the API calls performed.
    ///
    func testOnCreateTodoUnauthRole() async throws {
        if try await isSignedIn() {
            await signOut()
        }
        try await onCreateTodoTest()
    }
    
    /// A subscription to onCreate todo should receive an event for each create Todo mutation API called
    ///
    /// - Given:  An onCreate Todo subscription established
    /// - When:
    ///    - Create todo mutations API called
    /// - Then:
    ///    - The subscription should receive mutation events corresponding to the API calls performed.
    ///
    func testOnCreateTodoAuthRole() async throws {
        try await createAuthenticatedUser()
        try await onCreateTodoTest()
    }
    
    func onCreateTodoTest() async throws {
        let connectedInvoked = asyncExpectation(description: "Connection established")
        let progressInvoked = asyncExpectation(description: "progress invoked", expectedFulfillmentCount: 2)
        let disconnectedInvoked = asyncExpectation(description: "Connection disconnected")
        let subscription = Amplify.API.subscribe(request: .subscription(of: Todo.self, type: .onCreate))
        let uuid = UUID().uuidString
        let uuid2 = UUID().uuidString
        let name = String("\(#function)".dropLast(2))
        Task {
            for try await event in subscription {
                switch event {
                case .connection(let state):
                    switch state {
                    case .connecting:
                        break
                    case .connected:
                        await connectedInvoked.fulfill()
                    case .disconnected:
                        await disconnectedInvoked.fulfill()
                    }
                case .data(let result):
                    switch result {
                    case .success(let todo):
                        if todo.id == uuid || todo.id == uuid2 {
                            await progressInvoked.fulfill()
                        }
                    case .failure(let error):
                        XCTFail("\(error)")
                    }
                }
            }
        }
        
        await waitForExpectations([connectedInvoked], timeout: TestCommonConstants.networkTimeout)
        _ = try await createTodo(id: uuid, name: name)
        _ = try await createTodo(id: uuid2, name: name)
        await waitForExpectations([progressInvoked], timeout: TestCommonConstants.networkTimeout)
        subscription.cancel()
        await waitForExpectations([disconnectedInvoked], timeout: TestCommonConstants.networkTimeout)
    }

    // MARK: - Helpers
    
    func createTodo(id: String, name: String) async throws -> Todo {
        let todo = Todo(id: id, name: name)
        let event = try await Amplify.API.mutate(request: .create(todo))
        switch event {
        case .success(let data):
            return data
        case .failure(let error):
            throw error
        }
    }

    // MARK: - Auth Helpers
    
    func createAuthenticatedUser() async throws {
        if try await isSignedIn() {
            await signOut()
        }
        try await signUp()
        try await signIn()
    }
    
    func isSignedIn() async throws -> Bool {
        let authSession = try await Amplify.Auth.fetchAuthSession()
        return authSession.isSignedIn
    }
    
    func signUp() async throws {
        let signUpResult = try await Amplify.Auth.signUp(username: username, password: password)
        guard signUpResult.isSignUpComplete else {
            XCTFail("Sign up successful but not complete: \(signUpResult)")
            return
        }
    }
    
    func signIn() async throws {
        let signInResult = try await Amplify.Auth.signIn(username: username, password: password)
        guard signInResult.isSignedIn else {
            XCTFail("Sign in successful but not complete")
            return
        }
    }
    
    func signOut() async {
        _ = await Amplify.Auth.signOut()
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
