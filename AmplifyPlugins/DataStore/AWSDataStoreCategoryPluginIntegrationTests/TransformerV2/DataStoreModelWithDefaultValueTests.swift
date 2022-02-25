//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

/*
 # Assign Default Values for fields

 type TodoWithDefaultValueV2 @model {
   content: String @default(value: "My new Todo")
 }
 */

class DataStoreModelWithDefaultValueTests: SyncEngineIntegrationV2TestBase {

    func testSaveModelWithExplicitContentAndSync() throws {
        try startAmplifyAndWaitForSync()

        guard let todo = saveTodo(content: "content") else {
            XCTFail("Could not create todo")
            return
        }

        let createReceived = expectation(description: "Create notification received")
        let hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
                guard let mutationEvent = payload.data as? MutationEvent
                    else {
                        XCTFail("Can't cast payload as mutation event")
                        return
                }
                guard let todoEvent = try? mutationEvent.decodeModel() as? TodoWithDefaultValueV2,
                        todoEvent.id == todo.id else {
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(todoEvent.content, todo.content)
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                    return
                }
        }
        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        let getTodoCompleted = expectation(description: "get todo complete")
        Amplify.DataStore.query(TodoWithDefaultValueV2.self, byId: todo.id) { result in
            switch result {
            case .success(let queriedTodoOptional):
                guard let queriedTodo = queriedTodoOptional else {
                    XCTFail("Could not get todo")
                    return
                }
                XCTAssertEqual(queriedTodo.id, todo.id)
                getTodoCompleted.fulfill()
            case .failure(let response): XCTFail("Failed with: \(response)")
            }
        }

        wait(for: [getTodoCompleted, createReceived], timeout: TestCommonConstants.networkTimeout)
    }

    func testSaveModelWithoutExplicitContentAndSync() throws {
        try startAmplifyAndWaitForSync()

        guard let todo = saveTodo(content: nil) else {
            XCTFail("Could not create todo")
            return
        }

        let createReceived = expectation(description: "Create notification received")
        let hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
                guard let mutationEvent = payload.data as? MutationEvent
                    else {
                        XCTFail("Can't cast payload as mutation event")
                        return
                }
                guard let todoEvent = try? mutationEvent.decodeModel() as? TodoWithDefaultValueV2,
                        todoEvent.id == todo.id else {
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(todoEvent.content, "My new Todo")
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                    return
                }
        }
        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        let getTodoCompleted = expectation(description: "get todo complete")
        Amplify.DataStore.query(TodoWithDefaultValueV2.self, byId: todo.id) { result in
            switch result {
            case .success(let queriedTodoOptional):
                guard let queriedTodo = queriedTodoOptional else {
                    XCTFail("Could not get todo")
                    return
                }
                XCTAssertEqual(queriedTodo.id, todo.id)
                getTodoCompleted.fulfill()
            case .failure(let response): XCTFail("Failed with: \(response)")
            }
        }

        wait(for: [getTodoCompleted, createReceived], timeout: TestCommonConstants.networkTimeout)
    }

    func saveTodo(content: String?) -> TodoWithDefaultValueV2? {
        let todo = TodoWithDefaultValueV2(content: content)
        var result: TodoWithDefaultValueV2?
        let completeInvoked = expectation(description: "request completed")
        Amplify.DataStore.save(todo) { event in
            switch event {
            case .success(let data):
                result = data
                completeInvoked.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [completeInvoked], timeout: TestCommonConstants.networkTimeout)
        return result
    }
}

