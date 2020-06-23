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

/// Tests APIs that return StoragePublishers (that is, no in-process publisher)
class StoragePublisherTests: XCTestCase {

    var plugin: MockStorageCategoryPlugin!

    override func setUpWithError() throws {
        Amplify.reset()

        let categoryConfig = StorageCategoryConfiguration(
            plugins: ["MockStorageCategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(storage: categoryConfig)
        plugin = MockStorageCategoryPlugin()
        try Amplify.add(plugin: plugin)
        try Amplify.configure(amplifyConfig)
    }

    func testGetURLSucceeds() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true
        plugin.responders.getURL = { _, _, resultListener in
            resultListener?(.success(URL(fileURLWithPath: "file:///path/to/file")))
        }
        _ = Amplify.Storage.getURL(key: "key")
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    receivedError.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
    }

    func testGetURLFails() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")
        plugin.responders.getURL = { _, _, resultListener in
            resultListener?(.failure(.unknown("Test")))
        }
        _ = Amplify.Storage.getURL(key: "key")
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    receivedError.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
    }

    func testRemoveSucceeds() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true
        plugin.responders.remove = { _, _, resultListener in
            resultListener?(.success("Test"))
        }
        _ = Amplify.Storage.remove(key: "key")
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    receivedError.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
    }

    func testRemoveFails() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")
        plugin.responders.remove = { _, _, resultListener in
            resultListener?(.failure(.unknown("Test")))
        }
        _ = Amplify.Storage.remove(key: "key")
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    receivedError.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
    }

    func testListSucceeds() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true
        plugin.responders.list = { _, resultListener in
            resultListener?(.success(StorageListResult(items: [])))
        }
        _ = Amplify.Storage.list()
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    receivedError.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
    }

    func testListFails() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")
        plugin.responders.list = { _, resultListener in
            resultListener?(.failure(.unknown("Test")))
        }
        _ = Amplify.Storage.list()
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
