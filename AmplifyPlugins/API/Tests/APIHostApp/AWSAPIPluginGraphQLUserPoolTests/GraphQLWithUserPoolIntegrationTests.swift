//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import Foundation
import AWSAPIPlugin
import AWSCognitoAuthPlugin

@testable import Amplify
@testable import APIHostApp
// swiftlint:disable type_body_length
class GraphQLWithUserPoolIntegrationTests: XCTestCase {
    let amplifyConfigurationFile = "testconfiguration/GraphQLWithUserPoolIntegrationTests-amplifyconfiguration"

    let username = "integTest\(UUID().uuidString)"
    let password = "P123@\(UUID().uuidString)"
  
    override func setUp() {
        do {
            try Amplify.add(plugin: AWSAPIPlugin())
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(
                forResource: amplifyConfigurationFile)
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func tearDown() async throws {
        await signOut()
        await Amplify.reset()
    }
    
    /// Given: A CreateTodo mutation request, and user signed in, graphql has userpools as auth mode.
    /// When: Call mutate API
    /// Then: The operation completes successfully with no errors and todo in response
    func testCreateTodoMutationWithUserPoolWithSignedInUser() async throws {
        try await createAuthenticatedUser()
        let expectedId = UUID().uuidString
        let expectedName = "testCreateTodoMutationName"
        let expectedDescription = "testCreateTodoMutationDescription"
        let request = GraphQLRequest(document: CreateTodoMutation.document,
                                     variables: CreateTodoMutation.variables(id: expectedId,
                                                                             name: expectedName,
                                                                             description: expectedDescription),
                                     responseType: CreateTodoMutation.Data.self)
        let graphQLResponse = try await Amplify.API.mutate(request: request)
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
    }

    /// Given: GraphQL with userPool, no user signed in, Cognito configured with no guest access.
    /// When: Call mutate API
    /// Then: The operation fails with error, user not signed in.
    func testCreateTodoMutationWithUserPoolWithoutSignedInUserFailsWithError() async {
        await signOut()
        let expectedId = UUID().uuidString
        let expectedName = "testCreateTodoMutationName"
        let expectedDescription = "testCreateTodoMutationDescription"
        let request = GraphQLRequest(document: CreateTodoMutation.document,
                                     variables: CreateTodoMutation.variables(id: expectedId,
                                                                             name: expectedName,
                                                                             description: expectedDescription),
                                     responseType: CreateTodoMutation.Data.self)
        do {
            let graphQLResponse = try await Amplify.API.mutate(request: request)
            XCTFail("Unexpected .completed event: \(graphQLResponse)")
        } catch {
            print("Got error back because user not signed in: \(error)")
        }
    }

    /// Given: A CreateTodo mutation request
    /// When: Call mutate API
    /// Then: The operation creates a Todo successfully, Todo object is returned, and empty errors array
    func testCreateTodoMutation() async throws {
        try await createAuthenticatedUser()
        let expectedId = UUID().uuidString
        let expectedName = "testCreateTodoMutationName"
        let expectedDescription = "testCreateTodoMutationDescription"
        let request = GraphQLRequest(document: CreateTodoMutation.document,
                                     variables: CreateTodoMutation.variables(id: expectedId,
                                                                             name: expectedName,
                                                                             description: expectedDescription),
                                     responseType: Todo?.self,
                                     decodePath: CreateTodoMutation.decodePath)

        let graphQLResponse = try await Amplify.API.mutate(request: request)
        guard case let .success(data) = graphQLResponse else {
            XCTFail("Missing successful response")
            return
        }
        
        guard let todo = data else {
            XCTFail("Missing Todo")
            return
        }
        
        XCTAssertEqual(todo.id, expectedId)
        XCTAssertEqual(todo.name, expectedName)
        XCTAssertEqual(todo.description, expectedDescription)
        XCTAssertEqual(todo.typename, String(describing: Todo.self))
    }

    /// Given: A CreateTodo mutation request with input variable in document and missing values from variables
    /// When: Call mutate API
    /// Then: The mutation operation completes successfully with errors in graphQLResponse
    func testCreateTodoMutationWithMissingInputFromVariables() async throws {
        try await createAuthenticatedUser()
        let uuid = UUID().uuidString

        // create a Todo mutation with a missing/invalid "name" variable value
        let request = GraphQLRequest(document: CreateTodoMutation.document,
                                     variables: CreateTodoMutation.variables(id: uuid,
                                                                             name: nil,
                                                                             description: nil),
                                     responseType: Todo?.self,
                                     decodePath: CreateTodoMutation.decodePath)
        let graphQLResponse = try await Amplify.API.mutate(request: request)
        guard case let .failure(graphQLResponseError) = graphQLResponse else {
            XCTFail("Unexpected response success \(graphQLResponse)")
            return
        }
        guard case let .error(errors) = graphQLResponseError, let firstError = errors.first else {
            XCTFail("Missing errors")
            return
        }
        XCTAssertEqual("Variable 'input' has coerced Null value for NonNull type 'String!'",
                       firstError.message)
    }

    /// Given: A CreateTodo mutation request with incorrect repsonse type (ListTodo instead of Todo)
    /// When: Call mutate API
    /// Then: The mutation operation fails with APIError
    func testCreateTodoMutationWithInvalidResponseType() async throws {
        try await createAuthenticatedUser()
        let expectedId = UUID().uuidString
        let expectedName = "testCreateTodoMutationName"
        let expectedDescription = "testCreateTodoMutationDescription"
        let request = GraphQLRequest(document: CreateTodoMutation.document,
                                     variables: CreateTodoMutation.variables(id: expectedId,
                                                                             name: expectedName,
                                                                             description: expectedDescription),
                                     responseType: MalformedCreateTodoData.self)
        let graphQLResponse = try await Amplify.API.mutate(request: request)
        guard case let .failure(graphQLResponseError) = graphQLResponse else {
            XCTFail("Unexpected event: \(graphQLResponse)")
            return
        }
        
        guard case .transformationError = graphQLResponseError else {
            XCTFail("Should be transformation error")
            return
        }
    }

    /// Given: A Todo is created successfully
    /// When: Call query API for that Todo
    /// Then: The query operation returns successfully with the Todo object and empty errors
    func testGetTodoQuery() async throws {
        try await createAuthenticatedUser()
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let name = testMethodName + "Name"
        let description = testMethodName + "Description"
        guard let todo = try await createTodo(id: uuid, name: name, description: description) else {
            XCTFail("Failed to set up test")
            return
        }

        let request = GraphQLRequest(document: GetTodoQuery.document,
                                     variables: GetTodoQuery.variables(id: todo.id),
                                     responseType: GetTodoQuery.Data.self)
        let graphQLResponse = try await Amplify.API.query(request: request)
        guard case let .success(data) = graphQLResponse else {
            XCTFail("Missing successful response")
            return
        }
        guard let todo = data.getTodo else {
            XCTFail("Missing Todo")
            return
        }
        
        XCTAssertEqual(todo.id, todo.id)
        XCTAssertEqual(todo.name, name)
        XCTAssertEqual(todo.description, description)
        XCTAssertEqual(todo.typename, String(describing: Todo.self))
    }

    /// Given: A newly generated random uuid
    /// When: Call query API
    /// Then: The query operation successfully with no errors and empty Todo object
    func testGetTodoQueryForMissingTodo() async throws {
        try await createAuthenticatedUser()
        let uuid = UUID().uuidString
        let request = GraphQLRequest(document: GetTodoQuery.document,
                                     variables: GetTodoQuery.variables(id: uuid),
                                     responseType: GetTodoQuery.Data.self)
        let graphQLResponse = try await Amplify.API.query(request: request)
        guard case let .success(data) = graphQLResponse else {
            XCTFail("Missing successful response")
            return
        }
        XCTAssertNil(data.getTodo)
    }

    /// Given: A successful Todo created and an Update mutation request
    /// When: Call mutate API
    /// Then: The operation updates the Todo successfully and the Todo object is returned
    func testUpdateTodoMutation() async throws {
        try await createAuthenticatedUser()
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let name = testMethodName + "Name"
        let description = testMethodName + "Description"
        guard let todo = try await createTodo(id: uuid, name: name, description: description) else {
            XCTFail("Failed to set up test")
            return
        }
        let expectedName = name + "Updated"
        let expectedDescription = description + "Updated"
        let request = GraphQLRequest(document: UpdateTodoMutation.document,
                                     variables: UpdateTodoMutation.variables(id: todo.id,
                                                                             name: expectedName,
                                                                             description: expectedDescription),
                                     responseType: UpdateTodoMutation.Data.self)
        let graphQLResponse = try await Amplify.API.mutate(request: request)
        guard case let .success(data) = graphQLResponse else {
            XCTFail("Missing successful response")
            return
        }
        guard let todo = data.updateTodo else {
            XCTFail("Missing Todo")
            return
        }
        XCTAssertEqual(todo.id, todo.id)
        XCTAssertEqual(todo.name, expectedName)
        XCTAssertEqual(todo.description, expectedDescription)
        XCTAssertEqual(todo.typename, String(describing: Todo.self))
    }

    /// Given: A successful Todo created and a Delete mutation request
    /// When: Call mutatate API with DeleteTodo mutation
    /// Then: The operation deletes the Todo successfully, Todo object is returned, and an query returns empty
    func testDeleteTodoMutation() async throws {
        try await createAuthenticatedUser()
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let name = testMethodName + "Name"
        let description = testMethodName + "Description"
        guard let todo = try await createTodo(id: uuid, name: name, description: description) else {
            XCTFail("Failed to set up test")
            return
        }

        let request = GraphQLRequest(document: DeleteTodoMutation.document,
                                     variables: DeleteTodoMutation.variables(id: todo.id),
                                     responseType: DeleteTodoMutation.Data.self)
        let graphQLResponse = try await Amplify.API.mutate(request: request)
        guard case let .success(data) = graphQLResponse else {
            XCTFail("Missing successful response")
            return
        }
        guard let deleteTodo = data.deleteTodo else {
            XCTFail("Missing deleteTodo")
            return
        }
        
        XCTAssertEqual(deleteTodo.id, todo.id)
        XCTAssertEqual(deleteTodo.name, name)
        XCTAssertEqual(deleteTodo.description, description)
        XCTAssertEqual(deleteTodo.typename, String(describing: Todo.self))

        let getTodoRequest = GraphQLRequest(document: GetTodoQuery.document,
                                            variables: GetTodoQuery.variables(id: todo.id),
                                            responseType: GetTodoQuery.Data.self)
        let graphQLResponse2 = try await Amplify.API.query(request: getTodoRequest)
        XCTAssertNotNil(graphQLResponse2)
        
        guard case let .success(data) = graphQLResponse2 else {
            XCTFail("Missing successful response")
            return
        }
        
        XCTAssertNil(data.getTodo)
    }

    /// Given: A successful Todo created
    /// When: Call query API with ListTodo mutation for all Todos
    /// Then: The operation completes successfully with list of Todos returned
    func testListTodosQuery() async throws {
        try await createAuthenticatedUser()
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let name = testMethodName + "Name"
        let description = testMethodName + "Description"
        guard try await createTodo(id: uuid, name: name, description: description) != nil else {
            XCTFail("Failed to set up test")
            return
        }

        let request = GraphQLRequest(document: ListTodosQuery.document,
                                     variables: nil,
                                     responseType: ListTodosQuery.Data.self)
        let graphQLResponse = try await Amplify.API.query(request: request)
        switch graphQLResponse {
        case .success(let data):
            guard let listTodos = data.listTodos else {
                XCTFail("Missing listTodos")
                return
            }
            XCTAssertTrue(!listTodos.items.isEmpty)
        case .failure(let error):
            print("\(error.underlyingError)")
            XCTFail("Unexpected .failed event: \(error)")
        }
    }

    /// When: Call query API with ListTodo mutation with filter on the random Id
    /// Then: The operation completes successfully with no errors and empty list
    func testListTodosQueryWithNoResults() async throws {
        try await createAuthenticatedUser()
        let uuid = UUID().uuidString
        let filter = ["id": ["eq": uuid]]
        let variables = ListTodosQuery.variables(filter: filter, limit: 10)
        let request = GraphQLRequest(document: ListTodosQuery.document,
                                     variables: variables,
                                     responseType: ListTodosQuery.Data.self)
        let graphQLResponse = try await Amplify.API.query(request: request)
        guard case let .success(data) = graphQLResponse else {
            XCTFail("Missing successful response")
            return
        }
        guard let listTodos = data.listTodos else {
            XCTFail("Missing listTodos")
            return
        }
        XCTAssertEqual(listTodos.items.count, 0)
    }

    /// The user is not signed in so establishing the subscription will fail with an unauthorized error.
    func testOnCreateSubscriptionUnauthorized() async throws {
        Amplify.Logging.logLevel = .verbose
        let connectingInvoked = asyncExpectation(description: "Connecting invoked")
        let connectedInvoked = asyncExpectation(description: "Connection established", isInverted: true)
        let completedInvoked = asyncExpectation(description: "Completed invoked")
        let request = GraphQLRequest(document: OnCreateTodoSubscription.document,
                                     variables: nil,
                                     responseType: OnCreateTodoSubscription.Data.self)
        let subscriptions = Amplify.API.subscribe(request: request)

        Task {
            do {
                for try await subscription in subscriptions {
                    switch subscription {
                    case .connection(let state):
                        switch state {
                        case .connecting:
                            await connectingInvoked.fulfill()
                        case .connected:
                            await connectedInvoked.fulfill()
                        case .disconnected:
                            break
                        }
                    case .data:
                        break
                    }
                }
            } catch {
                if let apiError = error as? APIError, apiError.isUnauthorized() {
                    await completedInvoked.fulfill()
                }
            }
        }
        await waitForExpectations([connectingInvoked, connectedInvoked, completedInvoked], timeout: TestCommonConstants.networkTimeout)
    }

    /// Given: A successful subscription is created for CreateTodo's
    /// When: Call mutate API on CreateTodo
    /// Then: The subscription handler is called and Todo object is returned
    func testOnCreateTodoSubscription() async throws {
        try await createAuthenticatedUser()
        let connectedInvoked = asyncExpectation(description: "Connection established")
        let disconnectedInvoked = asyncExpectation(description: "Connection disconnected")
        let completedInvoked = asyncExpectation(description: "Completed invoked")
        let progressInvoked = asyncExpectation(description: "progress invoked", expectedFulfillmentCount: 2)
        let request = GraphQLRequest(document: OnCreateTodoSubscription.document,
                                     variables: nil,
                                     responseType: OnCreateTodoSubscription.Data.self)
        let subscriptions = Amplify.API.subscribe(request: request)
        Task {
            for try await subscription in subscriptions {
                switch subscription {
                case .connection(let state):
                    switch state {
                    case .connecting:
                        break
                    case .connected:
                        await connectedInvoked.fulfill()
                    case .disconnected:
                        await disconnectedInvoked.fulfill()
                    }
                case .data:
                    Task { await progressInvoked.fulfill() }
                }
            }
            
            await completedInvoked.fulfill()
        }
        await waitForExpectations([connectedInvoked], timeout: TestCommonConstants.networkTimeout)
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let name = testMethodName + "Name"
        let description = testMethodName + "Description"

        guard try await createTodo(id: uuid, name: name, description: description) != nil else {
            XCTFail("Failed to create todo")
            return
        }

        let uuid2 = UUID().uuidString
        guard try await createTodo(id: uuid2, name: name, description: description) != nil else {
            XCTFail("Failed to create todo")
            return
        }

        await waitForExpectations([progressInvoked], timeout: TestCommonConstants.networkTimeout)
        subscriptions.cancel()
        await waitForExpectations([disconnectedInvoked, completedInvoked], timeout: TestCommonConstants.networkTimeout)
    }

    /// Given: A subscription is created for UpdateTodo's
    /// When: Call mutate API on UpdateTodo
    /// Then: The subscription handler is called and Todo object is returned
    func testOnUpdateTodoSubscription() async throws {
        try await createAuthenticatedUser()
        let connectedInvoked = asyncExpectation(description: "Connection established")
        let disconnectedInvoked = asyncExpectation(description: "Connection disconnected")
        let completedInvoked = asyncExpectation(description: "Completed invoked")
        let progressInvoked = asyncExpectation(description: "progress invoked", expectedFulfillmentCount: 2)
        let request = GraphQLRequest(document: OnUpdateTodoSubscription.document,
                                     variables: nil,
                                     responseType: OnUpdateTodoSubscription.Data.self)
        let subscriptions = Amplify.API.subscribe(request: request)
        Task {
            for try await subscription in subscriptions {
                switch subscription {
                case .connection(let state):
                    switch state {
                    case .connecting:
                        break
                    case .connected:
                        Task { await connectedInvoked.fulfill() }
                    case .disconnected:
                        Task { await disconnectedInvoked.fulfill() }
                    }
                case .data:
                    Task { await progressInvoked.fulfill() }
                }
            }
            await completedInvoked.fulfill()
        }
        await waitForExpectations([connectedInvoked], timeout: TestCommonConstants.networkTimeout)
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let name = testMethodName + "Name"
        let description = testMethodName + "Description"

        guard let todo = try await createTodo(id: uuid, name: name, description: description) else {
            XCTFail("Failed to create todo")
            return
        }

        guard try await updateTodo(id: todo.id, name: name + "Updated", description: description) != nil else {
            XCTFail("Failed to update todo")
            return
        }

        guard try await updateTodo(id: todo.id, name: name + "Updated2", description: description) != nil else {
            XCTFail("Failed to update todo")
            return
        }

        await waitForExpectations([progressInvoked], timeout: TestCommonConstants.networkTimeout)
        subscriptions.cancel()
        await waitForExpectations([disconnectedInvoked, completedInvoked], timeout: TestCommonConstants.networkTimeout)
    }

    /// Given: A subscription is created for DeleteTodo
    /// When: Call mutate API on DeleteTodo
    /// Then: The subscription handler is called and Todo object is returned
    func testOnDeleteTodoSubscription() async throws {
        try await createAuthenticatedUser()
        let connectedInvoked = asyncExpectation(description: "Connection established")
        let disconnectedInvoked = asyncExpectation(description: "Connection disconnected")
        let completedInvoked = asyncExpectation(description: "Completed invoked")
        let progressInvoked = asyncExpectation(description: "progress invoked")
        let request = GraphQLRequest(document: OnDeleteTodoSubscription.document,
                                     variables: nil,
                                     responseType: OnDeleteTodoSubscription.Data.self)
        let subscriptions = Amplify.API.subscribe(request: request)
        Task {
            for try await subscription in subscriptions {
                switch subscription {
                case .connection(let state):
                    switch state {
                    case .connecting:
                        break
                    case .connected:
                        Task { await connectedInvoked.fulfill() }
                    case .disconnected:
                        Task { await disconnectedInvoked.fulfill() }
                    }
                case .data:
                    Task { await progressInvoked.fulfill() }
                }
            }
            await completedInvoked.fulfill()
        }
        await waitForExpectations([connectedInvoked], timeout: TestCommonConstants.networkTimeout)
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let name = testMethodName + "Name"
        let description = testMethodName + "Description"

        guard let todo = try await createTodo(id: uuid, name: name, description: description) else {
            XCTFail("Failed to create todo")
            return
        }

        guard try await deleteTodo(id: todo.id) != nil else {
            XCTFail("Failed to delete todo")
            return
        }

        await waitForExpectations([progressInvoked], timeout: TestCommonConstants.networkTimeout)
        
        subscriptions.cancel()
        await waitForExpectations([disconnectedInvoked, completedInvoked], timeout: TestCommonConstants.networkTimeout)
    }

    func testCreateMultipleSubscriptions() async throws {
        try await createAuthenticatedUser()
        let subscriptions = [await createTodoSubscription(),
                             await createTodoSubscription(),
                             await createTodoSubscription(),
                             await createTodoSubscription(),
                             await createTodoSubscription()]
        for subscription in subscriptions {
            subscription.cancel()
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
            XCTFail("Sign up successful but not complete")
            return
        }
    }

    func signIn() async throws {
        let signInResult = try await Amplify.Auth.signIn(username: username,
                                                         password: password)
        guard signInResult.isSignedIn else {
            XCTFail("Sign in successful but not complete")
            return
        }
    }
    
    func signOut() async {
        _ = await Amplify.Auth.signOut()
    }

    // MARK: - Helpers
    
    func createTodo(id: String, name: String, description: String) async throws -> Todo? {
        let request = GraphQLRequest(document: CreateTodoMutation.document,
                                     variables: CreateTodoMutation.variables(id: id,
                                                                             name: name,
                                                                             description: description),
                                     responseType: CreateTodoMutation.Data.self)
        let graphQLResponse = try await Amplify.API.mutate(request: request)
        switch graphQLResponse {
        case .success(let data):
            return data.createTodo
        case .failure(let error):
            throw error
        }
    }

    func updateTodo(id: String, name: String, description: String) async throws -> Todo? {
        let request = GraphQLRequest(document: UpdateTodoMutation.document,
                                     variables: UpdateTodoMutation.variables(id: id,
                                                                             name: name,
                                                                             description: description),
                                     responseType: UpdateTodoMutation.Data.self)
        let graphQLResponse = try await Amplify.API.mutate(request: request)
        switch graphQLResponse {
        case .success(let data):
            return data.updateTodo
        case .failure(let error):
            throw error
        }
    }

    func deleteTodo(id: String) async throws -> Todo? {
        let request = GraphQLRequest(document: DeleteTodoMutation.document,
                                     variables: DeleteTodoMutation.variables(id: id),
                                     responseType: DeleteTodoMutation.Data.self)
        let graphQLResponse = try await Amplify.API.mutate(request: request)
        switch graphQLResponse {
        case .success(let data):
            return data.deleteTodo
        case .failure(let error):
            throw error
        }
    }

    func createTodoSubscription() async -> AmplifyAsyncThrowingSequence<GraphQLSubscriptionEvent<OnCreateTodoSubscription.Data>> {
        let connectedInvoked = asyncExpectation(description: "Connection established")
        let request = GraphQLRequest(document: OnCreateTodoSubscription.document,
                                     variables: nil,
                                     responseType: OnCreateTodoSubscription.Data.self)
        let subscriptions = Amplify.API.subscribe(request: request)
        Task {
            for try await subscription in subscriptions {
                switch subscription {
                case .connection(let state):
                    switch state {
                    case .connected:
                        await connectedInvoked.fulfill()
                    default:
                        break
                    }
                default:
                    break
                }
            }
        }
        await waitForExpectations([connectedInvoked], timeout: TestCommonConstants.networkTimeout)
        return subscriptions
    }
}
