//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Combine
import XCTest

import Amplify
import AWSPluginsCore
import AWSDataStorePlugin

extension AWSDataStoreLazyLoadPostComment4V2Tests {

    static let loggingContext = "multiSaveWithInterruptions"

    /// Test performing save's and stop/start concurrently. 
    ///
    /// This test was validated prior to [PR 3492](https://github.com/aws-amplify/amplify-swift/pull/3492)
    /// and will fail. The failure will show up when the test asserts that a queried comment from AppSync should contain the associated
    /// post, but comment's post is `nil`. See the PR for changes in adding transactional support for commiting the two writes (saving the model and
    /// mutation event) and MutationEvent dequeuing logic.
    ///
    /// - Given: A set of models (post and comment) created and saved to DataStore.
    /// - When: A detached task will interrupt DataStore by calling `DataStore.stop()`,
    ///     followed by restarting it (`DataStore.start()`), while saving comment and posts.
    /// - Then:
    ///     - DataStore should sync data in the correct order of what was saved/submitted to it
    ///         - the post should be synced before the comment
    ///         - it should not skip over an item, ie. a comment saved but post is missing.
    ///     - The remote store should contain all items synced
    ///         - comments and post should exist.
    ///         - the comment should also have the post reference.
    ///
    func testMultiSaveWithInterruptions() async throws {
        await setup(withModels: PostComment4V2Models())
        let amplify = AmplifyTestExecutor()

        Amplify.Logging.info("[\(AWSDataStoreLazyLoadPostComment4V2Tests.loggingContext)] Begin saving data with interruptions")
        let savesSyncedExpectation = expectation(description: "Outbox is empty after saving (with interruptions)")
        savesSyncedExpectation.assertForOverFulfill = false
        try await amplify.multipleSavesWithInterruptions(savesSyncedExpectation)
        await fulfillment(of: [savesSyncedExpectation], timeout: 120)

        Amplify.Logging.info("[\(AWSDataStoreLazyLoadPostComment4V2Tests.loggingContext)] Outbox is empty, begin asserting data")
        let savedModels = await amplify.savedModels
        for savedModel in savedModels {
            let savedComment = savedModel.0
            let savedPost = savedModel.1

            try await assertQueryComment(savedComment, post: savedPost)
            try await assertQueryPost(savedPost)
        }
        Amplify.Logging.info("[\(AWSDataStoreLazyLoadPostComment4V2Tests.loggingContext)] All models match remote store, begin clean up.")
        try await cleanUp(savedModels)
    }

    actor AmplifyTestExecutor {
        var savedModels = [(Comment, Post)]()

        /// The minimum number of iterations, through trial and error, found to reproduce the bug.
        private let count = 15
        
        /// `isOutboxEmpty` is used to return the flow back to the caller via fulfilling the `savesSyncedExpectation`.
        /// By listening to the OutboxEvent after performing the operations, the last outboxEvent to be `true` while `index`
        /// is the last index, will be when `savesSyncedExpectation` is fulfilled and returned execution back to the caller.
        private var isOutboxEmpty = false

        private var index = 0
        private var subscribeToOutboxEventTask: Task<Void, Never>?
        private var outboxEventsCount = 0

        /// Perform saving the comment/post in one detached task while another detached task will
        /// perform the interruption (stop/start). Repeat with a bit of delay to allow DataStore some
        /// time to kick off its start sequence- this will always be the case since the last operation of
        /// each detached task is a `save` (implicit `start`) or a `start`.
        func multipleSavesWithInterruptions(_ savesSyncedExpectation: XCTestExpectation) async throws {
            subscribeToOutboxEvent(savesSyncedExpectation)
            while isOutboxEmpty == false {
                try await Task.sleep(seconds: 1)
            }
            for i in 0..<count {
                let post = Post(title: "title")
                let comment = Comment(content: "content", post: post)
                savedModels.append((comment,post))

                Task.detached {
                    Amplify.Logging.info("[\(AWSDataStoreLazyLoadPostComment4V2Tests.loggingContext)] Saving comment and post, index: \(i)")
                    do {
                        _ = try await Amplify.DataStore.save(post)
                        _ = try await Amplify.DataStore.save(comment)
                    } catch {
                        // This is expected to happen when DataStore is interrupted and did not save the MutationEvent.
                        Amplify.Logging.info("[\(AWSDataStoreLazyLoadPostComment4V2Tests.loggingContext)] Failed to save post and/or comment, post: \(post.id). comment: \(comment.id). error \(error)")
                    }
                }
                Task.detached {
                    Amplify.Logging.info("[\(AWSDataStoreLazyLoadPostComment4V2Tests.loggingContext)] Stop/Start, index: \(i)")
                    try await Amplify.DataStore.stop()
                    try await Amplify.DataStore.start()
                }
                self.index = i
                try await Task.sleep(seconds: 0.01)
            }
        }

        /// Subscribe to DataStore Hub events, and handle `OutboxStatusEvent`'s.
        /// Maintain the latest state of whether the outbox is empty or not in `isOutboxEmpty` variable.
        /// Fulfill `savesSyncedExpectation` after all tasks have been created and the outbox is empty.
        private func subscribeToOutboxEvent(_ savesSyncedExpectation: XCTestExpectation) {
            self.subscribeToOutboxEventTask = Task {
                for await event in Amplify.Hub.publisher(for: .dataStore).values {
                    switch event.eventName {
                    case HubPayload.EventName.DataStore.outboxStatus:
                        guard let outboxEvent = event.data as? OutboxStatusEvent else {
                            return
                        }
                        isOutboxEmpty = outboxEvent.isEmpty
                        outboxEventsCount += 1
                        Amplify.Logging.info("[\(AWSDataStoreLazyLoadPostComment4V2Tests.loggingContext)] \(outboxEventsCount) isOutboxEmpty: \(isOutboxEmpty), index: \(index)")
                        if index == (count - 1)  && isOutboxEmpty {
                            XCTAssertEqual(savedModels.count, count)
                            savesSyncedExpectation.fulfill()
                        }
                    default:
                        break
                    }
                }
            }
        }
    }

    func assertQueryComment(_ savedComment: Comment, post: Post) async throws {
        guard (try await Amplify.DataStore.query(
            Comment.self,
            byIdentifier: savedComment.identifier)) != nil else {
            Amplify.Logging.info("[\(AWSDataStoreLazyLoadPostComment4V2Tests.loggingContext)] Comment \(savedComment.id) is not persisted in local DB")

            let result = try await Amplify.API.query(
                request: .get(
                    Comment.self,
                    byIdentifier: savedComment.id))
            switch result {
            case .success(let comment):
                guard let comment else {
                    return
                }
                XCTFail("Cost \(comment.id) should not be in AppSync")
            case .failure(let error):
                XCTFail("Failed to query, error \(error)")
            }
            return
        }

        let result = try await Amplify.API.query(
            request: .get(
                Comment.self,
                byIdentifier: savedComment.id))
        switch result {
        case .success(let comment):
            guard let comment else {
                XCTFail("Missing comment, should contain \(savedComment)")
                return
            }
            assertLazyReference(
                comment._post,
                state: .notLoaded(
                    identifiers: [.init(
                        name: "id",
                        value: post.identifier)]))
        case .failure(let error):
            XCTFail("Failed to query, error \(error)")
        }
    }

    func assertQueryPost(_ savedPost: Post) async throws {
        guard (try await Amplify.DataStore.query(
            Post.self,
            byIdentifier: savedPost.identifier)) != nil else {
            Amplify.Logging.info("[\(AWSDataStoreLazyLoadPostComment4V2Tests.loggingContext)] Post \(savedPost.id) is not persisted in local DB")
            let result = try await Amplify.API.query(
                request: .get(
                    Post.self,
                    byIdentifier: savedPost.id))
            switch result {
            case .success(let post):
                guard let post else {
                    return
                }
                XCTFail("Post \(post.id) should not be in AppSync")
            case .failure(let error):
                XCTFail("Failed to query, error \(error)")
            }
            return
        }
        let result = try await Amplify.API.query(
            request: .get(
                Post.self,
                byIdentifier: savedPost.id))
        switch result {
        case .success(let post):
            guard post != nil else {
                XCTFail("Missing post, should contain \(savedPost)")
                return
            }
        case .failure(let error):
            XCTFail("Failed to query, error \(error)")
        }
    }

    func cleanUp(_ savedModels: [(Comment, Post)]) async throws {
        for savedModel in savedModels {
            let savedComment = savedModel.0
            let savedPost = savedModel.1

            do {
                _ = try await Amplify.API.mutate(
                    request: .deleteMutation(
                        of: savedComment,
                        modelSchema: Comment.schema,
                        version: 1))

                _ = try await Amplify.API.mutate(
                    request: .deleteMutation(
                        of: savedPost,
                        modelSchema: Post.schema,
                        version: 1))
            } catch {
                // Some models that fail to save don't need to be deleted,
                // swallowing the error to continue deleting others
            }
        }
    }
}

