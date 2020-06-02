//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

import AmplifyCombineSupport

@testable import Amplify
@testable import AmplifyTestCommon

class DataStoreCombineSupportTests: XCTestCase {

    var plugin: MockDataStoreCategoryPlugin!

    override func setUpWithError() throws {
        Amplify.reset()

        let dataStoreConfig = DataStoreCategoryConfiguration(
            plugins: ["MockDataStoreCategoryPlugin": true]
        )

        let config = AmplifyConfiguration(dataStore: dataStoreConfig)
        plugin = MockDataStoreCategoryPlugin()
        try Amplify.add(plugin: plugin)
        try Amplify.configure(config)
    }

    func testClearSucceeds() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true
        let responder: ClearResponder = { .successfulVoid }
        plugin.responders.clear = responder
        _ = Amplify.DataStore.clear()
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    receivedError.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
    }

    func testClearFails() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")
        let responder: ClearResponder = { .failure(DataStoreError.invalidModelName("Blah")) }
        plugin.responders.clear = responder
        _ = Amplify.DataStore.clear()
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    receivedError.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
    }

    func testDeleteByIdSucceeds() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true
        let responder: DeleteByIdResponder = { _, _ in .successfulVoid }
        plugin.responders.deleteById = responder
        _ = Amplify.DataStore.delete(Post.self, withId: "1")
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    receivedError.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
    }

    func testDeleteByIdFails() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")
        let responder: DeleteByIdResponder = { _, _ in
            .failure(DataStoreError.invalidModelName("Blah"))
        }
        plugin.responders.deleteById = responder
        _ = Amplify.DataStore.delete(Post.self, withId: "1")
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    receivedError.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
    }

    func testDeleteByInstanceSucceeds() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true
        let responder: DeleteByInstanceResponder = { _, _ in .successfulVoid }
        plugin.responders.deleteByInstance = responder
        let post = Post(title: "Title", content: "Content", createdAt: Temporal.DateTime.now())
        _ = Amplify.DataStore.delete(post)
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    receivedError.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
    }

    func testDeleteByInstanceFails() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")
        let responder: DeleteByInstanceResponder = { _, _ in
            .failure(DataStoreError.invalidModelName("Blah"))
        }
        plugin.responders.deleteByInstance = responder
        let post = Post(title: "T", content: "C", createdAt: Temporal.DateTime.now())
        _ = Amplify.DataStore.delete(post)
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    receivedError.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
    }

    func testQueryByIdSucceeds() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true
        let responder: QueryByIdResponder = { _, _ in
            .success(Post(title: "T", content: "C", createdAt: Temporal.DateTime.now()))
        }
        plugin.responders.queryById = responder
        _ = Amplify.DataStore.query(Post.self, byId: "1")
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    receivedError.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
    }

    func testQueryByIdFails() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")
        let responder: QueryByIdResponder = { _, _ in
            .failure(DataStoreError.invalidModelName("Blah"))
        }
        plugin.responders.queryById = responder
        _ = Amplify.DataStore.query(Post.self, byId: "1")
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    receivedError.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
    }

    func testQueryByPredicateSucceeds() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true
        let responder: QueryByPredicateResponder = { _, _, _ in
            .success([Post(title: "T", content: "C", createdAt: Temporal.DateTime.now())])
        }
        plugin.responders.queryByPredicate = responder
        _ = Amplify.DataStore.query(Post.self)
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    receivedError.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
    }

    func testQueryByPredicateFails() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")
        let responder: QueryByPredicateResponder = { _, _, _ in
            .failure(DataStoreError.invalidModelName("Blah"))
        }
        plugin.responders.queryByPredicate = responder
        _ = Amplify.DataStore.query(Post.self)
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    receivedError.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
    }

    func testSaveSucceeds() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true
        let responder: SaveResponder = { model, _ in .success(model) }
        plugin.responders.save = responder
        let post = Post(title: "T", content: "C", createdAt: Temporal.DateTime.now())
        _ = Amplify.DataStore.save(post)
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    receivedError.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
    }

    func testSaveFails() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")
        let responder: SaveResponder = { _, _ in
            .failure(DataStoreError.invalidModelName("Blah"))
        }
        plugin.responders.save = responder
        let post = Post(title: "T", content: "C", createdAt: Temporal.DateTime.now())
        _ = Amplify.DataStore.save(post)
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    receivedError.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
    }

}
