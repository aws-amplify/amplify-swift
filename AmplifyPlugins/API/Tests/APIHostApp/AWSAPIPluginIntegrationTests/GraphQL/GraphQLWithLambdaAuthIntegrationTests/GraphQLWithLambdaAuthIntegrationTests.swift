//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSAPIPlugin

@testable import Amplify
@testable import APIHostApp
@testable import AWSAPICategoryPluginTestCommon

class GraphQLWithLambdaAuthIntegrationTests: XCTestCase {
    let amplifyConfigurationFile = "testconfiguration/GraphQLWithLambdaAuthIntegrationTests-amplifyconfiguration"
    override func setUp() {
        do {
            try Amplify.add(plugin: AWSAPIPlugin(apiAuthProviderFactory: TestAPIAuthProviderFactory()))
            let amplifyConfig = try TestConfigHelper.retrieveAmplifyConfiguration(forResource: amplifyConfigurationFile)
            try Amplify.configure(amplifyConfig)

            ModelRegistry.register(modelType: Todo.self)
        } catch {
            XCTFail("Error during setup: \(error)")
        }
    }

    override func tearDown() {
        await Amplify.reset()
    }

    /// Test create mutation with a custom GraphQL Document
    ///
    /// - Given:  A custom GraphQL document containing CreateTodo mutation request
    /// - When:
    ///    - Call mutate API
    /// - Then:
    ///    - The operation completes successfully with no errors and todo in response
    ///
    func testCreateTodoMutation() {
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

    /// Test paginated query
    ///
    /// - Given:  paginated query request
    /// - When:
    ///    - Call API.query
    /// - Then:
    ///    - The operation completes successfully with no errors and a list of todos in response
    ///
    func testQueryTodos() {
        let completeInvoked = expectation(description: "request completed")
        let request = GraphQLRequest<Todo>.list(Todo.self)
        let sink = Amplify.API.query(request: request)
            .resultPublisher
            .sink {
                if case let .failure(error) = $0 {
                    XCTFail("Query failure with error \(error)")
                }
            }
            receiveValue: {
                switch $0 {
                case .failure(let error):
                    XCTFail("Received failure \(error)")
                case .success(let result):
                    XCTAssertNotNil(result)
                    completeInvoked.fulfill()
                }
            }
        XCTAssertNotNil(sink)
        waitForExpectations(timeout: TestCommonConstants.networkTimeout)
    }

    /// A subscription to onCreate todo should receive an event for each create Todo mutation API called
    ///
    /// - Given:  An onCreate Todo subscription established
    /// - When:
    ///    - Create todo mutations API called
    /// - Then:
    ///    - The subscription should receive mutation events corresponding to the API calls performed.
    ///
    func testOnCreateTodoSubscription() {
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
            XCTFail("Failed to create todo")
            return
        }

        wait(for: [progressInvoked], timeout: TestCommonConstants.networkTimeout)
        operation.cancel()
        wait(for: [disconnectedInvoked, completedInvoked], timeout: TestCommonConstants.networkTimeout)
        XCTAssertTrue(operation.isFinished)
    }

    // MARK: - Helpers

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
                    XCTFail("Create Todo was not successful: \(data)")
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

// MARK: - API Auth provider
private class CustomTokenProvider: AmplifyFunctionAuthProvider {
    func getLatestAuthToken() -> Result<AuthToken, Error> {
        .success("custom-lambda-token")
    }
}

private class TestAPIAuthProviderFactory: APIAuthProviderFactory {
    override func functionAuthProvider() -> AmplifyFunctionAuthProvider? {
        CustomTokenProvider()
    }
}
