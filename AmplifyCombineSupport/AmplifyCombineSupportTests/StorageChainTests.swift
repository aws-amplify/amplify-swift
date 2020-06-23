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

class StorageChainTests: XCTestCase {

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

    func testChainedOperationsSucceed() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true

        plugin.responders.downloadData = { _, _, _, resultListener in
            resultListener?(.success(Data()))
        }

        plugin.responders.uploadData = { _, _, _, _, resultListener in
            resultListener?(.success("test"))
        }

        plugin.responders.getURL = { _, _, resultListener in
            resultListener?(.success(URL(fileURLWithPath: "file:///path/to/file")))
        }

        let sink = Amplify.Storage.downloadData(key: "key").resultPublisher
            .flatMap { data in
                Amplify.Storage.uploadData(key: "key2", data: data).resultPublisher
        }.flatMap { _ in
            Amplify.Storage.getURL(key: "key2")
        }
        .sink(receiveCompletion: { completion in
            if case .failure = completion {
                receivedError.fulfill()
            }
        }, receiveValue: { _ in
            receivedValue.fulfill()
        })

        waitForExpectations(timeout: 0.05)
        sink.cancel()
    }

    func testChainedOperationsFail() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")

        plugin.responders.downloadData = { _, _, _, resultListener in
            resultListener?(.success(Data()))
        }

        plugin.responders.uploadData = { _, _, _, _, resultListener in
            resultListener?(.failure(.unknown("Test")))
        }

        plugin.responders.getURL = { _, _, resultListener in
            resultListener?(.success(URL(fileURLWithPath: "file:///path/to/file")))
        }

        let sink = Amplify.Storage.downloadData(key: "key").resultPublisher
            .flatMap { data in
                Amplify.Storage.uploadData(key: "key2", data: data).resultPublisher
        }.flatMap { _ in
            Amplify.Storage.getURL(key: "key2")
        }
        .sink(receiveCompletion: { completion in
            if case .failure = completion {
                receivedError.fulfill()
            }
        }, receiveValue: { _ in
            receivedValue.fulfill()
        })

        waitForExpectations(timeout: 0.05)
        sink.cancel()
    }

}
