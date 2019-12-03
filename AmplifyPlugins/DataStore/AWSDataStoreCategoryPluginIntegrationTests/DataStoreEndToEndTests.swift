//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AmplifyPlugins
import AWSMobileClient

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

// TODO: Delete mutation events from the database so that this can be run multiple times without having to remove the
// app from the device/simulator
@available(iOS 13.0, *)
class DataStoreEndToEndTests: SyncEngineIntegrationTestBase {

    func testCreateMutateDelete() throws {
        try startAmplifyAndWaitForSync()

        let newPost = Post(title: "This is a new post I created", content: "Original content at \(Date())")
        var updatedPost = newPost
        updatedPost.content = "UPDATED CONTENT at \(Date())"

        let createReceived = expectation(description: "Create notification received")
        let updateReceived = expectation(description: "Create notification received")
        let deleteReceived = expectation(description: "Create notification received")

        let hubListener = Amplify.Hub.listen(
            to: .dataStore,
            eventName: HubPayload.EventName.DataStore.syncReceived) { payload in
                guard let mutationEvent = payload.data as? MutationEvent,
                    let post = try? mutationEvent.decodeModel() as? Post
                    else {
                        XCTFail("Can't cast payload as mutation event")
                        return
                }

                if mutationEvent.mutationType == GraphQLMutationType.create.rawValue {
                    XCTAssertEqual(post.content, post.content)
                    XCTAssertEqual(mutationEvent.version, 1)
                    createReceived.fulfill()
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.update.rawValue {
                    XCTAssertEqual(post.content, updatedPost.content)
                    XCTAssertEqual(mutationEvent.version, 2)
                    updateReceived.fulfill()
                    return
                }

                if mutationEvent.mutationType == GraphQLMutationType.delete.rawValue {
                    deleteReceived.fulfill()
                    XCTAssertEqual(mutationEvent.version, 3)
                    return
                }
        }

        guard try HubListenerTestUtilities.waitForListener(with: hubListener, timeout: 5.0) else {
            XCTFail("Listener not registered for hub")
            return
        }

        Amplify.DataStore.save(newPost) { _ in }

        wait(for: [createReceived], timeout: networkTimeout)

        Amplify.DataStore.save(updatedPost) { _ in }

        wait(for: [updateReceived], timeout: networkTimeout)

        Amplify.DataStore.delete(updatedPost) { _ in }

        wait(for: [deleteReceived], timeout: networkTimeout)
    }
}
