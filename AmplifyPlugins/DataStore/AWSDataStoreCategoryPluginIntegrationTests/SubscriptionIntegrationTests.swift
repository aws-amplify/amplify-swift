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
// swiftlint:disable:next type_name
class SubscriptionIntegrationTests: XCTestCase {
    let networkTimeout = TimeInterval(180)

    var amplifyConfig: AmplifyConfiguration!

    // NOTE: This setUp does not invoke `Amplify.configure()`, to ensure the local tests have control over the time at
    // which sync startup happens.
    override func setUp() {
        super.setUp()

        Amplify.reset()
        Amplify.Logging.logLevel = .verbose

        ModelRegistry.register(modelType: Post.self)
        ModelRegistry.register(modelType: Comment.self)

        // TODO: Move this to an integ test config file
        let apiConfig = APICategoryConfiguration(plugins: [
            "awsAPIPlugin": [
                "default": [
                    "endpoint": "https://ldm7yqjfjngrjckbziumz5fxbe.appsync-api.us-west-2.amazonaws.com/graphql",
                    "region": "us-west-2",
                    "authorizationType": "API_KEY",
                    "apiKey": "da2-7jhi34lssbbmjclftlykznhw5m",
                    "endpointType": "GraphQL"
                ]
            ]
        ])

        let dataStoreConfig = DataStoreCategoryConfiguration(plugins: [
            "awsDataStoreCategoryPlugin": true
        ])

        amplifyConfig = AmplifyConfiguration(api: apiConfig, dataStore: dataStoreConfig)

        do {
            try Amplify.add(plugin: AWSAPIPlugin())
            try Amplify.add(plugin: AWSDataStoreCategoryPlugin())
        } catch {
            XCTFail(String(describing: error))
            return
        }
    }

    override func tearDown() {
        Amplify.reset()
    }

    /// - Given: An API-connected DataStore
    /// - When:
    ///    - I start Amplify
    /// - Then:
    ///    - I receive subscriptions from other systems for syncable models
    func testSubscribeAtStartup() throws {
        try Amplify.configure(amplifyConfig)

        let createdMutationReceived = expectation(description: "Created mutation received")
        let updatedMutationReceived = expectation(description: "Updated mutation received")
        let deletedMutationReceived = expectation(description: "Deleted mutation received")

        let sub = Amplify.DataStore.publisher(for: Post.self)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Unexpected error: \(error)")
                }
            }, receiveValue: { mutationEvent in
                guard let model = try? mutationEvent.decodeModel(as: Post.self) else {
                    XCTFail("Couldn't decode model")
                    return
                }

                if model._deleted ?? false {
                    deletedMutationReceived.fulfill()
                } else if model._version == 1 {
                    createdMutationReceived.fulfill()
                } else if model._version == 2 {
                    updatedMutationReceived.fulfill()
                }
            })

        // TODO: Need a better way of ensuring setup is complete before subscribing and sending syncable
        // mutations
        DispatchQueue.global().asyncAfter(deadline: .now() + 5.0) {
            // Simulate another system by creating, updating, and deleting a model directly via the API
//            let newPost = Post(title: "Post title",
//                               content: "Post content")
//            _ = Amplify.API.mutate(of: newPost, type: .create) { event in
//                print("Created event received: \(event)")
//            }

//            let updatedPost = Post(id: newPost.id,
//                                   title: newPost.title,
//                                   content: "Updated post content",
//                                   createdAt: newPost.createdAt,
//                                   updatedAt: newPost.updatedAt,
//                                   rating: newPost.rating,
//                                   draft: newPost.draft,
//                                   _version: 1)
//            _ = Amplify.API.mutate(of: updatedPost, type: .update, listener: nil)
//
//            let deletedPost = Post(id: updatedPost.id,
//                                   title: updatedPost.title,
//                                   content: "Updated post content",
//                                   createdAt: updatedPost.createdAt,
//                                   updatedAt: updatedPost.updatedAt,
//                                   rating: updatedPost.rating,
//                                   draft: updatedPost.draft,
//                                   _version: 2)
//            _ = Amplify.API.mutate(of: deletedPost, type: .delete, listener: nil)
        }

        wait(for: [createdMutationReceived, updatedMutationReceived, deletedMutationReceived],
             timeout: networkTimeout)

        sub.cancel()
    }

}
