//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import XCTest
import AWSPluginsCore

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

@available(iOS 13.0, *)
class DataStoreEndToEndTests: SyncEngineFlutterIntegrationTestBase {

    func testCreateMutateDelete() throws {
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        try startAmplifyAndWaitForSync()

        let title = "This is a new post I created"
        let date = Temporal.DateTime.now().iso8601String
        
        let newPost = try PostWrapper(
            title: title,
            content: "Original content from DataStoreEndToEndTests at \(date)")

        let updatedPost = try PostWrapper(
            id: newPost.idString(),
            title: title,
            content: "UPDATED CONTENT from DataStoreEndToEndTests at \(date)")

        let createReceived = expectation(description: "Create notification received")
        let updateReceived = expectation(description: "Update notification received")
        let deleteReceived = expectation(description: "Delete notification received")

        let hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
                guard let mutationEvent = payload.data as? MutationEvent
                    else {
                        XCTFail("Can't cast payload as mutation event")
                        return
                }
            
                guard let post = try? PostWrapper(json: mutationEvent.json), mutationEvent.modelName == "Post", post.idString() == newPost.idString() else {
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(post.content(), newPost.content())
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.update.rawValue {
                    XCTAssertEqual(post.content(), updatedPost.content())
                    XCTAssertEqual(mutationEvent.version, 2)
                    updateReceived.fulfill()
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    XCTAssertEqual(mutationEvent.version, 3)
                    deleteReceived.fulfill()
                    return
                }
        }

        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        plugin.save(newPost.model, modelSchema: Post.schema) { _ in }

        wait(for: [createReceived], timeout: networkTimeout)

        plugin.save(updatedPost.model, modelSchema: Post.schema) { _ in }

        wait(for: [updateReceived], timeout: networkTimeout)

        plugin.delete(updatedPost.model, modelSchema: Post.schema) { _ in }

        wait(for: [deleteReceived], timeout: networkTimeout)
    }

    /// - Given: A post that has been saved
    /// - When:
    ///    - attempt to update the existing post with a condition that matches existing data
    /// - Then:
    ///    - the update with condition that matches existing data will be applied and returned.
    func testCreateThenMutateWithCondition() throws {
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        try startAmplifyAndWaitForSync()
        
        let title = "This is a new post I created"
        let date = Temporal.DateTime.now().iso8601String
        
        let post = Post.keys

        let newPost = try PostWrapper(
            title: title,
            content: "Original content from DataStoreEndToEndTests at \(date)",
            createdAt: date)

        let updatedPost = try PostWrapper(
            id: newPost.idString(),
            title: title,
            content: "UPDATED CONTENT from DataStoreEndToEndTests at \(date)",
            createdAt: date
        )

        let createReceived = expectation(description: "Create notification received")
        let updateReceived = expectation(description: "Update notification received")

        let hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
                guard let mutationEvent = payload.data as? MutationEvent
                    else {
                        XCTFail("Can't cast payload as mutation event")
                        return
                }

                // This check is to protect against stray events being processed after the test has completed,
                // and it shouldn't be construed as a pattern necessary for production applications.
                guard let post = try? PostWrapper(json: mutationEvent.json), mutationEvent.modelName == "Post", post.idString() == newPost.idString() else {
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(post.content(), newPost.content())
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.update.rawValue {
                    XCTAssertEqual(post.content(), updatedPost.content())
                    XCTAssertEqual(mutationEvent.version, 2)
                    updateReceived.fulfill()
                    return
                }
        }

        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        plugin.save(newPost.model, modelSchema: Post.schema) { _ in }

        wait(for: [createReceived], timeout: networkTimeout)

        plugin.save(updatedPost.model, modelSchema: Post.schema, where: post.title == title) { _ in }

        wait(for: [updateReceived], timeout: networkTimeout)
    }

    /// Ensure DataStore.stop followed by DataStore.start is successful
    ///
    /// - Given:  DataStore has completely started
    /// - When:
    ///    - DataStore.stop
    ///    - Followed by DataStore.start in the completion of the stop
    /// - Then:
    ///    - Saving a post should be successful
    ///
    func testStopStart() throws {
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        try startAmplifyAndWaitForSync()
        let stopStartSuccess = expectation(description: "stop then start successful")
        plugin.stop { result in
            switch result {
            case .success:
                plugin.start { result in
                    switch result {
                    case .success:
                        stopStartSuccess.fulfill()
                    case .failure(let error):
                        XCTFail("\(error)")
                    }
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [stopStartSuccess], timeout: networkTimeout)
        try validateSavePost(plugin: plugin)

    }
    
    /// Ensure the DataStore is automatically started when querying for the first time
    ///
    /// - Given: DataStore is configured but not started
    /// - When:
    ///   - I call DataStore.query()
    /// - Then:
    ///   - DataStore is automatically started
    func testQueryImplicitlyStarts() throws {
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        let dataStoreStarted = expectation(description: "dataStoreStarted")
        let sink = Amplify
            .Hub
            .publisher(for: .dataStore)
            .filter { $0.eventName == HubPayload.EventName.DataStore.ready }
            .sink { _ in dataStoreStarted.fulfill() }

        let amplifyStarted = expectation(description: "amplifyStarted")
        try startAmplify {
            amplifyStarted.fulfill()
        }
        wait(for: [amplifyStarted], timeout: 1.0)

        // We expect the query to complete, but not to return a value. Thus, we'll ignore the error
        let queryCompleted = expectation(description: "queryCompleted")
        plugin.query(FlutterSerializedModel.self, modelSchema: Post.schema, where: Post.keys.id.eq("123")) { _ in queryCompleted.fulfill() }

        wait(for: [dataStoreStarted, queryCompleted], timeout: networkTimeout)
        sink.cancel()
    }
    
    /// Ensure DataStore.clear followed by DataStore.start is successful
    ///
    /// - Given:  DataStore has completely started
    /// - When:
    ///    - DataStore.clear
    ///    - Followed by DataStore.start in the completion of the clear
    /// - Then:
    ///    - Saving a post should be successful
    ///
    func testClearStart() throws {
        let plugin: AWSDataStorePlugin = try Amplify.DataStore.getPlugin(for: "awsDataStorePlugin") as! AWSDataStorePlugin
        try startAmplifyAndWaitForSync()
        let clearStartSuccess = expectation(description: "clear then start successful")
        plugin.clear { result in
            switch result {
            case .success:
                plugin.start { result in
                    switch result {
                    case .success:
                        clearStartSuccess.fulfill()
                    case .failure(let error):
                        XCTFail("\(error)")
                    }
                }
            case .failure(let error):
                XCTFail("\(error)")
            }
        }
        wait(for: [clearStartSuccess], timeout: networkTimeout)
        try validateSavePost(plugin: plugin)
    }
    
    // MARK: - Helpers
    func validateSavePost(plugin: AWSDataStorePlugin) throws {
        let date = Temporal.DateTime.now()
        let newPost = try PostWrapper(
            title: "This is a new post I created",
            content: "Original content from DataStoreEndToEndTests at \(date)",
            createdAt: Temporal.DateTime.now().iso8601String)
        let createReceived = expectation(description: "Create notification received")
        let hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
                guard let mutationEvent = payload.data as? MutationEvent
                    else {
                        XCTFail("Can't cast payload as mutation event")
                        return
                }

                // This check is to protect against stray events being processed after the test has completed,
                // and it shouldn't be construed as a pattern necessary for production applications.
                guard let post = try? PostWrapper(json: mutationEvent.json), mutationEvent.modelName == "Post", post.idString() == newPost.idString() else {
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(post.content(), newPost.content())
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                    return
                }
        }

        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        plugin.save(newPost.model, modelSchema: Post.schema) { _ in }
        wait(for: [createReceived], timeout: networkTimeout)
    }
}
