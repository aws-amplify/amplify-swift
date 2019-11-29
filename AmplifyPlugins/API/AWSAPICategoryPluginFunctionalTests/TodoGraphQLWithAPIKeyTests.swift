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
@testable import AWSAPICategoryPluginTestCommon

// swiftlint:disable type_body_length
// These test show the basic functionality of mutate/query/subscribe methods
class TodoGraphQLWithAPIKeyTests: XCTestCase {

    /*
     These are the instructions to set up the `todoGraphQLWithAPIKey` api. If for whatever reason, test resources are
     deleted from test credentails then these are the steps to recreate the resource:
     1. Run `amplify init` and choose `ios` for the type of app you're building

     2. Add api `amplify add api`
        * Please select from one of the below mentioned services `GraphQL`
        * Provide API name: `amplifyapigraphqlsam`
        * Choose the default authorization type for the API `API key`
        * Enter a description for the API key: `keyy`
        * After how many days from now the API key should expire (1-365): `180`
        * Do you want to configure advanced settings for the GraphQL API `No, I am done.`
        * Do you have an annotated GraphQL schema? `No`
        * Do you want a guided schema creation? `Yes`
        * What best describes your project: `Single object with fields (e.g., “Todo” with ID, name, description)`
        * Do you want to edit the schema now? `No`

     3. `amplify push`
        * Do you want to generate code for your newly created GraphQL API `Yes`
        * Enter the file name pattern of graphql queries, mutations and subscriptions `graphql/**/*.graphql`
        * Do you want to generate/update all possible GraphQL operations - queries, mutations and subscriptions `Yes`
        * Enter maximum statement depth [increase from default if your schema is deeply nested] `2`
        * Enter the file name for the generated code `API.swift`
         * GraphQL endpoint: `https://szc4yxxxxxxxxxxqaaiwoqe.appsync-api.us-east-1.amazonaws.com/graphql`
         * GraphQL API KEY: `da2-kjsuxxxxxxxxxx4pujny`
     */
    static let todoGraphQLWithAPIKey = "todoGraphQLWithAPIKey"

    override func setUp() {
        Amplify.reset()
        let plugin = AWSAPIPlugin()

        let apiConfig = APICategoryConfiguration(plugins: [
            "awsAPIPlugin": [
                TodoGraphQLWithAPIKeyTests.todoGraphQLWithAPIKey: [
                    "endpoint": "https://akeljq43xfcvpj4hh55fafcrm4.appsync-api.us-west-2.amazonaws.com/graphql",
                    "region": "us-west-2",
                    "authorizationType": "API_KEY",
                    "apiKey": "da2-6m3mowpbavh55kscoikywhqova",
                    "endpointType": "GraphQL"
                ],
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

    /// Given: A CreateTodo mutation request
    /// When: Call mutate API
    /// Then: The operation creates a Todo successfully, Todo object is returned, and empty errors array
    func testCreateTodoMutation() {
        let completeInvoked = expectation(description: "request completed")

        let expectedId = UUID().uuidString
        let expectedName = "testCreateTodoMutationName"
        let expectedDescription = "testCreateTodoMutationDescription"
        let request = GraphQLRequest(apiName: TodoGraphQLWithAPIKeyTests.todoGraphQLWithAPIKey,
                                     document: CreateTodoMutation.document,
                                     variables: CreateTodoMutation.variables(id: expectedId,
                                                                             name: expectedName,
                                                                             description: expectedDescription),
                                     responseType: Todo?.self,
                                     decodePath: CreateTodoMutation.decodePath)

        let operation = Amplify.API.mutate(request: request) { event in
            switch event {
            case .completed(let graphQLResponse):
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

    /// Given: A CreateTodo mutation request with input variable in document and missing values from variables
    /// When: Call mutate API
    /// Then: The mutation operation completes successfully with errors in graphQLResponse
    func testCreateTodoMutationWithMissingInputFromVariables() {
        let completeInvoked = expectation(description: "request completed")
        let uuid = UUID().uuidString
        let description = "testCreateTodoMutationWithMissingInputFromVariables"
        let request = GraphQLRequest(apiName: TodoGraphQLWithAPIKeyTests.todoGraphQLWithAPIKey,
                                     document: CreateTodoMutation.document,
                                     variables: CreateTodoMutation.variables(id: uuid,
                                                                             name: "",
                                                                             description: description),
                                     responseType: Todo?.self,
                                     decodePath: CreateTodoMutation.decodePath)
        let operation = Amplify.API.mutate(request: request) { event in
            switch event {
            case .completed(let graphQLResponse):
                guard case let .failure(graphQLResponseError) = graphQLResponse else {
                    XCTFail("Missing failure")
                    return
                }

                guard case let .partial(todo, error) = graphQLResponseError else {
                    XCTFail("Missing partial response")
                    return
                }
                print(graphQLResponseError.errorDescription)
                XCTAssertNil(todo)
                XCTAssertNotNil(error)
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

    /// Given: A CreateTodo mutation request with incorrect repsonse type (ListTodo instead of Todo)
    /// When: Call mutate API
    /// Then: The mutation operation fails with APIError
    func testCreateTodoMutationWithInvalidResponseType() {
        let transformationErrorInvoked = expectation(description: "transform error invoked")

        let expectedId = UUID().uuidString
        let expectedName = "testCreateTodoMutationName"
        let expectedDescription = "testCreateTodoMutationDescription"
        let request = GraphQLRequest(apiName: TodoGraphQLWithAPIKeyTests.todoGraphQLWithAPIKey,
                                     document: CreateTodoMutation.document,
                                     variables: CreateTodoMutation.variables(id: expectedId,
                                                                             name: expectedName,
                                                                             description: expectedDescription),
                                     responseType: MalformedCreateTodoData.self)
        let operation = Amplify.API.mutate(request: request) { event in
            switch event {
            case .completed(let graphQLResponse):
                guard case let .failure(graphQLResponseError) = graphQLResponse else {
                    XCTFail("Unexpected event: \(graphQLResponse)")
                    return
                }

                guard case .transformationError = graphQLResponseError else {
                    XCTFail("Should be transformation error")
                    return
                }
                transformationErrorInvoked.fulfill()
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }
        XCTAssertNotNil(operation)
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
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
        let request = GraphQLRequest(apiName: TodoGraphQLWithAPIKeyTests.todoGraphQLWithAPIKey,
                                     document: GetTodoQuery.document,
                                     variables: GetTodoQuery.variables(id: todo.id),
                                     responseType: GetTodoQuery.Data.self)
        let queryOperation = Amplify.API.query(request: request) { event in
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
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    /// Given: A newly generated random uuid
    /// When: Call query API
    /// Then: The query operation successfully with no errors and empty Todo object
    func testGetTodoQueryForMissingTodo() {
        let uuid = UUID().uuidString

        let completeInvoked = expectation(description: "request completed")
        let request = GraphQLRequest(apiName: TodoGraphQLWithAPIKeyTests.todoGraphQLWithAPIKey,
                                     document: GetTodoQuery.document,
                                     variables: GetTodoQuery.variables(id: uuid),
                                     responseType: GetTodoQuery.Data.self)
        let operation = Amplify.API.query(request: request) { event in
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
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
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
        let request = GraphQLRequest(apiName: TodoGraphQLWithAPIKeyTests.todoGraphQLWithAPIKey,
                                     document: UpdateTodoMutation.document,
                                     variables: UpdateTodoMutation.variables(id: todo.id,
                                                                             name: expectedName,
                                                                             description: expectedDescription),
                                     responseType: UpdateTodoMutation.Data.self)
        let operation = Amplify.API.mutate(request: request) { event in
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
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
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
        let request = GraphQLRequest(apiName: TodoGraphQLWithAPIKeyTests.todoGraphQLWithAPIKey,
                                     document: DeleteTodoMutation.document,
                                     variables: DeleteTodoMutation.variables(id: todo.id),
                                     responseType: DeleteTodoMutation.Data.self)
        let deleteOperation = Amplify.API.mutate(request: request) { event in
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
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)

        let queryCompleteInvoked = expectation(description: "request completed")
        let getTodoRequest = GraphQLRequest(apiName: TodoGraphQLWithAPIKeyTests.todoGraphQLWithAPIKey,
                                            document: GetTodoQuery.document,
                                            variables: GetTodoQuery.variables(id: todo.id),
                                            responseType: GetTodoQuery.Data.self)
        let queryOperation = Amplify.API.query(request: getTodoRequest) { event in
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
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    // TODO: first time run fails, hm
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
        let request = GraphQLRequest(apiName: TodoGraphQLWithAPIKeyTests.todoGraphQLWithAPIKey,
                                     document: ListTodosQuery.document,
                                     variables: nil,
                                     responseType: ListTodosQuery.Data.self)
        let operation = Amplify.API.query(request: request) { event in
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
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    /// When: Call query API with ListTodo mutation with filter on the random Id
    /// Then: The operation completes successfully with no errors and empty list
    func testListTodosQueryWithNoResults() {
        let uuid = UUID().uuidString
        let filter = ["id": ["eq": uuid]]
        let variables = ListTodosQuery.variables(filter: filter, limit: 10)
        let listCompleteInvoked = expectation(description: "request completed")
        let request = GraphQLRequest(apiName: TodoGraphQLWithAPIKeyTests.todoGraphQLWithAPIKey,
                                     document: ListTodosQuery.document,
                                     variables: variables,
                                     responseType: ListTodosQuery.Data.self)
        let operation = Amplify.API.query(request: request) { event in
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
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    /// Given: A successful subscription is created for CreateTodo's
    /// When: Call mutate API on CreateTodo
    /// Then: The subscription handler is called and Todo object is returned
    func testOnCreateTodoSubscription() {
        let connectedInvoked = expectation(description: "Connection established")
        let disconnectedInvoked = expectation(description: "Connection disconnected")
        let completedInvoked = expectation(description: "Completed invoked")
        let progressInvoked = expectation(description: "progress invoked")
        progressInvoked.expectedFulfillmentCount = 2
        let request = GraphQLRequest(apiName: TodoGraphQLWithAPIKeyTests.todoGraphQLWithAPIKey,
                                     document: OnCreateTodoSubscription.document,
                                     variables: nil,
                                     responseType: OnCreateTodoSubscription.Data.self)
        let operation = Amplify.API.subscribe(request: request) { event in
            switch event {
            case .inProcess(let graphQLResponse):
                print(graphQLResponse)
                switch graphQLResponse {
                case .connection(let state):
                    switch state {
                    case .connecting:
                        break
                    case .connected:
                        connectedInvoked.fulfill()
                    case .disconnected:
                        disconnectedInvoked.fulfill()
                    }

                case .data(let graphQLResponse):
                    progressInvoked.fulfill()
                }
            case .failed(let error):
                print("Unexpected .failed event: \(error)")
            case .completed:
                completedInvoked.fulfill()
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }
        XCTAssertNotNil(operation)
        wait(for: [connectedInvoked], timeout: TestCommonConstants.networkTimeout)
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let name = testMethodName + "Name"
        let description = testMethodName + "Description"

        guard createTodo(id: uuid, name: name, description: description) != nil else {
            XCTFail("Failed to create todo")
            return
        }

        let uuid2 = UUID().uuidString
        guard createTodo(id: uuid2, name: name, description: description) != nil else {
            XCTFail("Failed to create todo")
            return
        }

        wait(for: [progressInvoked], timeout: TestCommonConstants.networkTimeout)
        operation.cancel()
        wait(for: [disconnectedInvoked, completedInvoked], timeout: TestCommonConstants.networkTimeout)
        XCTAssertTrue(operation.isFinished)
    }

    /// Given: A subscription is created for UpdateTodo's
    /// When: Call mutate API on UpdateTodo
    /// Then: The subscription handler is called and Todo object is returned
    func testOnUpdateTodoSubscription() {
        let connectedInvoked = expectation(description: "Connection established")
        let disconnectedInvoked = expectation(description: "Connection disconnected")
        let completedInvoked = expectation(description: "Completed invoked")
        let progressInvoked = expectation(description: "progress invoked")
        progressInvoked.expectedFulfillmentCount = 2
        let request = GraphQLRequest(apiName: TodoGraphQLWithAPIKeyTests.todoGraphQLWithAPIKey,
                                     document: OnUpdateTodoSubscription.document,
                                     variables: nil,
                                     responseType: OnUpdateTodoSubscription.Data.self)
        let operation = Amplify.API.subscribe(request: request) { event in
            switch event {
            case .inProcess(let graphQLResponse):
                print(graphQLResponse)
                switch graphQLResponse {
                case .connection(let state):
                    switch state {
                    case .connecting:
                        break
                    case .connected:
                        connectedInvoked.fulfill()
                    case .disconnected:
                        disconnectedInvoked.fulfill()
                    }

                case .data(let graphQLResponse):
                    progressInvoked.fulfill()
                }
            case .failed(let error):
                print("Unexpected .failed event: \(error)")
            case .completed:
                completedInvoked.fulfill()
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }
        XCTAssertNotNil(operation)
        wait(for: [connectedInvoked], timeout: TestCommonConstants.networkTimeout)
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let name = testMethodName + "Name"
        let description = testMethodName + "Description"

        guard let todo = createTodo(id: uuid, name: name, description: description) else {
            XCTFail("Failed to create todo")
            return
        }

        guard updateTodo(id: todo.id, name: name + "Updated", description: description) != nil else {
            XCTFail("Failed to update todo")
            return
        }

        guard updateTodo(id: todo.id, name: name + "Updated2", description: description) != nil else {
            XCTFail("Failed to update todo")
            return
        }

        wait(for: [progressInvoked], timeout: TestCommonConstants.networkTimeout)
        operation.cancel()
        wait(for: [disconnectedInvoked, completedInvoked], timeout: TestCommonConstants.networkTimeout)
        XCTAssertTrue(operation.isFinished)
    }

    /// Given: A subscription is created for DeleteTodo
    /// When: Call mutate API on DeleteTodo
    /// Then: The subscription handler is called and Todo object is returned
    func testOnDeleteTodoSubscription() {
        let connectedInvoked = expectation(description: "Connection established")
        let disconnectedInvoked = expectation(description: "Connection disconnected")
        let completedInvoked = expectation(description: "Completed invoked")
        let progressInvoked = expectation(description: "progress invoked")
        let request = GraphQLRequest(apiName: TodoGraphQLWithAPIKeyTests.todoGraphQLWithAPIKey,
                                     document: OnDeleteTodoSubscription.document,
                                     variables: nil,
                                     responseType: OnDeleteTodoSubscription.Data.self)
        let operation = Amplify.API.subscribe(request: request) { event in
            switch event {
            case .inProcess(let graphQLResponse):
                print(graphQLResponse)
                switch graphQLResponse {
                case .connection(let state):
                    switch state {
                    case .connecting:
                        break
                    case .connected:
                        connectedInvoked.fulfill()
                    case .disconnected:
                        disconnectedInvoked.fulfill()
                    }

                case .data(let graphQLResponse):
                    progressInvoked.fulfill()
                }
            case .failed(let error):
                print("Unexpected .failed event: \(error)")
            case .completed:
                completedInvoked.fulfill()
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }
        XCTAssertNotNil(operation)
        wait(for: [connectedInvoked], timeout: TestCommonConstants.networkTimeout)
        let uuid = UUID().uuidString
        let testMethodName = String("\(#function)".dropLast(2))
        let name = testMethodName + "Name"
        let description = testMethodName + "Description"

        guard let todo = createTodo(id: uuid, name: name, description: description) else {
            XCTFail("Failed to create todo")
            return
        }

        guard deleteTodo(id: todo.id, name: name + "Updated", description: description) != nil else {
            XCTFail("Failed to update todo")
            return
        }

        wait(for: [progressInvoked], timeout: TestCommonConstants.networkTimeout)
        operation.cancel()
        wait(for: [disconnectedInvoked, completedInvoked], timeout: TestCommonConstants.networkTimeout)
        XCTAssertTrue(operation.isFinished)
    }

    // Query with two query documents, return two different objects.
    func testCreateMultipleSubscriptions() {
        let operations = [createTodoSubscription(),
                          createTodoSubscription(),
                          createTodoSubscription(),
                          createTodoSubscription(),
                          createTodoSubscription()]
        let completedInvoked = expectation(description: "Completed invoked")
        completedInvoked.expectedFulfillmentCount = operations.count
        for operation in operations {
            _ = operation.subscribe { event in
                switch event {
                case .completed:
                    completedInvoked.fulfill()
                case .failed(let error):
                    XCTFail("Unexpected .failed event: \(error)")
                default:
                    break
                }
            }
            XCTAssertTrue(operation.isExecuting)
            operation.cancel()
        }
        wait(for: [completedInvoked], timeout: TestCommonConstants.networkTimeout)
        for operation in operations {
            XCTAssertTrue(operation.isFinished)
        }
    }

    // MARK: Common functionality

    func createTodo(id: String, name: String, description: String) -> Todo? {
        let completeInvoked = expectation(description: "Completd is invoked")
        var todo: Todo?

        let request = GraphQLRequest(apiName: TodoGraphQLWithAPIKeyTests.todoGraphQLWithAPIKey,
                                     document: CreateTodoMutation.document,
                                     variables: CreateTodoMutation.variables(id: id,
                                                                             name: name,
                                                                             description: description),
                                     responseType: CreateTodoMutation.Data.self)
        _ = Amplify.API.mutate(request: request) { event in
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
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return todo
    }

    func updateTodo(id: String, name: String, description: String) -> Todo? {
        let completeInvoked = expectation(description: "Completd is invoked")
        var todo: Todo?

        let request = GraphQLRequest(apiName: TodoGraphQLWithAPIKeyTests.todoGraphQLWithAPIKey,
                                     document: UpdateTodoMutation.document,
                                     variables: UpdateTodoMutation.variables(id: id,
                                                                             name: name,
                                                                             description: description),
                                     responseType: UpdateTodoMutation.Data.self)
        _ = Amplify.API.mutate(request: request) { event in
            switch event {
            case .completed(let graphQLResponse):
                guard case let .success(data) = graphQLResponse else {
                    XCTFail("Missing successful response")
                    return
                }
                guard let updateTodo = data.updateTodo else {
                    XCTFail("Missing createTodo")
                    return
                }

                todo = updateTodo
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Unexpected .failed event: \(error)")
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return todo
    }

    func deleteTodo(id: String, name: String, description: String) -> Todo? {
        let completeInvoked = expectation(description: "Completd is invoked")
        var todo: Todo?

        let request = GraphQLRequest(apiName: TodoGraphQLWithAPIKeyTests.todoGraphQLWithAPIKey,
                                     document: DeleteTodoMutation.document,
                                     variables: DeleteTodoMutation.variables(id: id),
                                     responseType: DeleteTodoMutation.Data.self)
        _ = Amplify.API.mutate(request: request) { event in
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

                todo = deleteTodo
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Unexpected .failed event: \(error)")
            default:
                XCTFail("Unexpected event: \(event)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return todo
    }

    func createTodoSubscription() -> GraphQLSubscriptionOperation<OnCreateTodoSubscription.Data> {
        let connectedInvoked = expectation(description: "Connection established")
        let request = GraphQLRequest(apiName: TodoGraphQLWithAPIKeyTests.todoGraphQLWithAPIKey,
                                     document: OnCreateTodoSubscription.document,
                                     variables: nil,
                                     responseType: OnCreateTodoSubscription.Data.self)
        let operation = Amplify.API.subscribe(request: request) { event in
            switch event {
            case .inProcess(let graphQLResponse):
                print(graphQLResponse)
                switch graphQLResponse {
                case .connection(let state):
                    switch state {
                    case .connected:
                        connectedInvoked.fulfill()
                    default:
                        break
                    }
                default:
                    break
                }
            default:
                break
            }
        }
        XCTAssertNotNil(operation)
        wait(for: [connectedInvoked], timeout: TestCommonConstants.networkTimeout)
        return operation
    }
}
