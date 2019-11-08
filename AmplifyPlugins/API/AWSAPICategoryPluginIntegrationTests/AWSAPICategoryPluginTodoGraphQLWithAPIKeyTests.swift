//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSMobileClient
import AWSAPICategoryPlugin
@testable import Amplify

// These test show the basic functionality of mutate/query/subscribe methods
class AWSAPICategoryPluginTodoGraphQLWithAPIKeyTests: AWSAPICategoryPluginBaseTests {

    /// Given: A CreateTodo mutation request
    /// When: Call mutate API
    /// Then: The operation creates a Todo successfully, Todo object is returned, and empty errors array
    func testCreateTodoMutation() {
        let completeInvoked = expectation(description: "request completed")

        let expectedId = UUID().uuidString
        let expectedName = "testCreateTodoMutationName"
        let expectedDescription = "testCreateTodoMutationDescription"
        let operation = Amplify.API.mutate(apiName: IntegrationTestConfiguration.todoGraphQLWithAPIKey,
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

    /// Given: A CreateTodo mutation request with input variable in document and missing values from variables
    /// When: Call mutate API
    /// Then: The mutation operation completes successfully with errors in graphQLResponse
    func testCreateTodoMutationWithMissingInputFromVariables() {
        let completeInvoked = expectation(description: "request completed")
        let uuid = UUID().uuidString
        let description = "testCreateTodoMutationWithMissingInputFromVariables"
        let operation = Amplify.API.mutate(apiName: IntegrationTestConfiguration.todoGraphQLWithAPIKey,
                                           document: CreateTodoMutation.document,
                                           variables: CreateTodoMutation.variables(id: uuid,
                                                                                   name: "",
                                                                                   description: description),
                                           responseType: CreateTodoMutation.Data.self) { (event) in
            switch event {
            case .completed(let graphQLResponse):
                guard case let .partial(data, error) = graphQLResponse else {
                    XCTFail("Missing partial response")
                    return
                }
                XCTAssertNil(data.createTodo)
                XCTAssertNotNil(error)
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

    /// Given: A CreateTodo mutation request with incorrect repsonse type (ListTodo instead of Todo)
    /// When: Call mutate API
    /// Then: The mutation operation fails with APIError
    func testCreateTodoMutationWithInvalidResponseType() {
        let failureInvoked = expectation(description: "request failed")

        let expectedId = UUID().uuidString
        let expectedName = "testCreateTodoMutationName"
        let expectedDescription = "testCreateTodoMutationDescription"

        let operation = Amplify.API.mutate(apiName: IntegrationTestConfiguration.todoGraphQLWithAPIKey,
                                           document: CreateTodoMutation.document,
                                           variables: CreateTodoMutation.variables(id: expectedId,
                                                                                   name: expectedName,
                                                                                   description: expectedDescription),
                                           responseType: MalformedCreateTodoData.self) { (event) in
            switch event {
            case .completed(let graphQLResponse):
                XCTFail("Unexpected .completed event: \(graphQLResponse)")
            case .failed(let error):
                // TODO: check error is some decoding issue
                failureInvoked.fulfill()
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: AWSAPICategoryPluginBaseTests.networkTimeout)
    }

    /// Given: A Todo is created successfully
    /// When: Call query API for that Todo
    /// Then: The query operation returns successfully with the Todo object and empty errors
    func testGetTodoQuery() {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let name = testMethodName + "Name"
        let description = testMethodName + "Description"
        guard let todo = createTodo(id: uuid, name: name, description: description) else {
            XCTFail("Failed to set up test")
            return
        }

        let completeInvoked = expectation(description: "request completed")
        let queryOperation = Amplify.API.query(apiName: IntegrationTestConfiguration.todoGraphQLWithAPIKey,
                                               document: GetTodoQuery.document,
                                               variables: GetTodoQuery.variables(id: todo.id),
                                               responseType: GetTodoQuery.Data.self) { (event) in
            switch event {
            case .completed(let graphQLResponse):
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

                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Unexpected .failed event: \(error)")
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }
        XCTAssertNotNil(queryOperation)
        waitForExpectations(timeout: AWSAPICategoryPluginBaseTests.networkTimeout)
    }

    /// Given: A newly generated random uuid
    /// When: Call query API
    /// Then: The query operation successfully with no errors and empty Todo object
    func testGetTodoQueryForMissingTodo() {
        let uuid = UUID().uuidString

        let completeInvoked = expectation(description: "request completed")
        let operation = Amplify.API.query(apiName: IntegrationTestConfiguration.todoGraphQLWithAPIKey,
                                          document: GetTodoQuery.document,
                                          variables: GetTodoQuery.variables(id: uuid),
                                          responseType: GetTodoQuery.Data.self) { (event) in
            switch event {
            case .completed(let graphQLResponse):
                guard case let .success(data) = graphQLResponse else {
                    XCTFail("Missing successful response")
                    return
                }

                XCTAssertNil(data.getTodo)
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

    /// Given: A successful Todo created and an Update mutation request
    /// When: Call mutate API
    /// Then: The operation updates the Todo successfully and the Todo object is returned
    func testUpdateTodoMutation() {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let name = testMethodName + "Name"
        let description = testMethodName + "Description"
        guard let todo = createTodo(id: uuid, name: name, description: description) else {
            XCTFail("Failed to set up test")
            return
        }
        let expectedName = name + "Updated"
        let expectedDescription = description + "Updated"
        let completeInvoked = expectation(description: "request completed")

        let operation = Amplify.API.mutate(apiName: IntegrationTestConfiguration.todoGraphQLWithAPIKey,
                                           document: UpdateTodoMutation.document,
                                           variables: UpdateTodoMutation.variables(id: todo.id,
                                                                                   name: expectedName,
                                                                                   description: expectedDescription),
                                           responseType: UpdateTodoMutation.Data.self) { (event) in
            switch event {
            case .completed(let graphQLResponse):
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

    /// Given: A successful Todo created and a Delete mutation request
    /// When: Call mutatate API with DeleteTodo mutation
    /// Then: The operation deletes the Todo successfully, Todo object is returned, and an query returns empty
    func testDeleteTodoMutation() {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let name = testMethodName + "Name"
        let description = testMethodName + "Description"
        guard let todo = createTodo(id: uuid, name: name, description: description) else {
            XCTFail("Failed to set up test")
            return
        }

        let deleteCompleteInvoked = expectation(description: "request completed")
        let deleteOperation = Amplify.API.mutate(apiName: IntegrationTestConfiguration.todoGraphQLWithAPIKey,
                                           document: DeleteTodoMutation.document,
                                           variables: DeleteTodoMutation.variables(id: todo.id),
                                           responseType: DeleteTodoMutation.Data.self) { (event) in
            switch event {
            case .completed(let graphQLResponse):
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
                deleteCompleteInvoked.fulfill()
            case .failed(let error):
                XCTFail("Unexpected .failed event: \(error)")
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }
        XCTAssertNotNil(deleteOperation)
        waitForExpectations(timeout: AWSAPICategoryPluginBaseTests.networkTimeout)

        let queryCompleteInvoked = expectation(description: "request completed")
        let queryOperation = Amplify.API.query(apiName: IntegrationTestConfiguration.todoGraphQLWithAPIKey,
                                               document: GetTodoQuery.document,
                                               variables: GetTodoQuery.variables(id: todo.id),
                                               responseType: GetTodoQuery.Data.self) { (event) in
            switch event {
            case .completed(let graphQLResponse):
                XCTAssertNotNil(graphQLResponse)

                guard case let .success(data) = graphQLResponse else {
                    XCTFail("Missing successful response")
                    return
                }

                XCTAssertNil(data.getTodo)
                queryCompleteInvoked.fulfill()
            case .failed(let error):
                XCTFail("Unexpected .failed event: \(error)")
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }
        XCTAssertNotNil(queryOperation)
        waitForExpectations(timeout: AWSAPICategoryPluginBaseTests.networkTimeout)
    }

    /// Given: A successful Todo created
    /// When: Call query API with ListTodo mutation for all Todos
    /// Then: The operation completes successfully with list of Todos returned
    func testListTodosQuery() {
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let name = testMethodName + "Name"
        let description = testMethodName + "Description"
        guard createTodo(id: uuid, name: name, description: description) != nil else {
            XCTFail("Failed to set up test")
            return
        }

        let listCompleteInvoked = expectation(description: "request completed")
        let operation = Amplify.API.query(apiName: IntegrationTestConfiguration.todoGraphQLWithAPIKey,
                                          document: ListTodosQuery.document,
                                          variables: nil,
                                          responseType: ListTodosQuery.Data.self) { (event) in
            switch event {
            case .completed(let graphQLResponse):
                guard case let .success(data) = graphQLResponse else {
                    XCTFail("Missing successful response")
                    return
                }
                guard let listTodos = data.listTodos else {
                    XCTFail("Missing listTodos")
                    return
                }

                XCTAssertTrue(!listTodos.items.isEmpty)
                listCompleteInvoked.fulfill()
            case .failed(let error):
                XCTFail("Unexpected .failed event: \(error)")
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: AWSAPICategoryPluginBaseTests.networkTimeout)
    }

    /// When: Call query API with ListTodo mutation with filter on the random Id
    /// Then: The operation completes successfully with no errors and empty list
    func testListTodosQueryWithNoResults() {
        let uuid = UUID().uuidString
        let filter = ["id": ["eq": uuid]]
        let variables = ListTodosQuery.variables(filter: filter, limit: 10)
        let listCompleteInvoked = expectation(description: "request completed")
        let operation = Amplify.API.query(apiName: IntegrationTestConfiguration.todoGraphQLWithAPIKey,
                                          document: ListTodosQuery.document,
                                          variables: variables,
                                          responseType: ListTodosQuery.Data.self) { (event) in
            switch event {
            case .completed(let graphQLResponse):
                guard case let .success(data) = graphQLResponse else {
                    XCTFail("Missing successful response")
                    return
                }
                guard let listTodos = data.listTodos else {
                    XCTFail("Missing listTodos")
                    return
                }

                XCTAssertEqual(listTodos.items.count, 0)
                listCompleteInvoked.fulfill()
            case .failed(let error):
                XCTFail("Unexpected .failed event: \(error)")
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: AWSAPICategoryPluginBaseTests.networkTimeout)
    }

    /// Given: A successful subscription is created for CreateTodo's
    /// When: Call mutate API on CreateTodo
    /// Then: The subscription handler is called and Todo object is returned
    func testOnCreateTodoSubscription() {
    }

    /// Given: A subscription is created for UpdateTodo's
    /// When: Call mutate API on UpdateTodo
    /// Then: The subscription handler is called and Todo object is returned
    func testOnUpdateTodoSubscription() {
    }

    /// Given: A subscription is created for DeleteTodo
    /// When: Call mutate API on DeleteTodo
    /// Then: The subscription handler is called and Todo object is returned
    func testOnDeleteTodoSubscription() {
    }

    // Query with two query documents, return two different objects.
    func testComplexQuery() {

    }

    // MARK: Common functionality

    func createTodo(id: String, name: String, description: String) -> Todo? {
        let completeInvoked = expectation(description: "Completd is invoked")
        var todo: Todo?

        _ = Amplify.API.mutate(apiName: IntegrationTestConfiguration.todoGraphQLWithAPIKey,
                                           document: CreateTodoMutation.document,
                                           variables: CreateTodoMutation.variables(id: id,
                                                                                   name: name,
                                                                                   description: description),
                                           responseType: CreateTodoMutation.Data.self) { (event) in
            switch event {
            case .completed(let graphQLResponse):
                guard case let .success(data) = graphQLResponse else {
                    XCTFail("Missing successful response")
                    return
                }
                guard let createTodo = data.createTodo else {
                    XCTFail("Missing createTodo")
                    return
                }

                todo = createTodo
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Unexpected .failed event: \(error)")
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }
        waitForExpectations(timeout: AWSAPICategoryPluginBaseTests.networkTimeout)
        return todo
    }
}
