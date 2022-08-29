//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Amplify
@testable import AWSDataStorePlugin

/*
 # Customize creation and update timestamp

 type TodoCustomTimestampV2 @model(timestamps: { createdAt: "createdOn", updatedAt: "updatedOn" }) {
   content: String
 }

 */

class DataStoreModelWithCustomTimestampTests: SyncEngineIntegrationV2TestBase {

    struct TestModelRegistration: AmplifyModelRegistration {
        func registerModels(registry: ModelRegistry.Type) {
            registry.register(modelType: TodoCustomTimestampV2.self)
        }

        let version: String = "1"
    }

    // TODO: Upates are not working due to CLI provisioning issue. the Update mutation is missing the `id`
    // https://github.com/aws-amplify/amplify-cli/issues/9136
    func testSaveModelAndSync() async throws {
        await setUp(withModels: TestModelRegistration())
        try startAmplifyAndWaitForSync()

        guard var todo = saveTodo(content: "content") else {
            XCTFail("Could not create blog, posts, and comments")
            return
        }
        let updatedContent = "updatedContent"
        let createReceived = expectation(description: "Create notification received")
        // let updateReceived = expectation(description: "Update notification received")
        var receivedTodoResult: TodoCustomTimestampV2?
        let deleteReceived = expectation(description: "Delete notification received")
        let hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
                guard let mutationEvent = payload.data as? MutationEvent
                    else {
                        XCTFail("Can't cast payload as mutation event")
                        return
                }
                guard let todoEvent = try? mutationEvent.decodeModel() as? TodoCustomTimestampV2, todoEvent.id == todo.id else {
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(todoEvent.content, todo.content)
                    XCTAssertNotNil(todoEvent.createdOn)
                    XCTAssertNotNil(todoEvent.updatedOn)
                    receivedTodoResult = todoEvent
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                    return
                } else if mutationEvent.mutationType == GraphQLMutationType.update.rawValue {
                    XCTAssertEqual(mutationEvent.version, 2)
                    // updateReceived.fulfill()
                } else if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    // TODO: assert on version 3 once updates are working
                    // XCTAssertEqual(mutationEvent.version, 3)
                    XCTAssertEqual(mutationEvent.version, 2)
                    deleteReceived.fulfill()
                }

        }
        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }
        let getTodoCompleted = expectation(description: "get todo complete")

        Amplify.DataStore.query(TodoCustomTimestampV2.self, byId: todo.id) { result in
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

        /*
          This failed with "The variables input contains a field name \'id\' that is not defined for input object
         type \'UpdateTodoCustomTimestampV2Input\' ", locations: nil, path: nil, extensions: nil)]
         */
//        guard var receivedTodo = receivedTodoResult else {
//            XCTFail("Failed to query todo")
//            return
//        }
//        receivedTodo.content = updatedContent
//        let updateCompleted = expectation(description: "update completed")
//        Amplify.DataStore.save(receivedTodo) { event in
//            switch event {
//            case .success(let todo):
//                XCTAssertEqual(todo.content, updatedContent)
//                updateCompleted.fulfill()
//            case .failure(let error):
//                XCTFail("Failed \(error)")
//            }
//        }
//        wait(for: [updateCompleted, updateReceived], timeout: TestCommonConstants.networkTimeout)

        let deleteCompleted = expectation(description: "delete completed")
        Amplify.DataStore.delete(TodoCustomTimestampV2.self, withId: todo.id) { event in
            switch event {
            case .success:
                deleteCompleted.fulfill()
            case .failure(let error):
                XCTFail("Failed \(error)")
            }
        }
        wait(for: [deleteCompleted, deleteReceived], timeout: TestCommonConstants.networkTimeout)
    }

    func saveTodo(content: String) -> TodoCustomTimestampV2? {
        let todo = TodoCustomTimestampV2(content: content)
        var result: TodoCustomTimestampV2?
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
