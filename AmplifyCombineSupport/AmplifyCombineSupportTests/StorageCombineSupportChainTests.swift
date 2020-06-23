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

class ChainTests: XCTestCase {

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

        plugin.responders.downloadData = { _, _, _ in
            .success(Data())
        }

        plugin.responders.uploadData = { _, _, _, _ in
            .success("test")
        }

        plugin.responders.getURL = { _, _ in
            .success(URL(fileURLWithPath: "file:///path/to/file"))
        }

        let sink = Amplify.Storage.downloadData(key: "key")
            .flatMap { data in
                Amplify.Storage.uploadData(key: "key2", data: data)
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

        plugin.responders.downloadData = { _, _, _ in
            .success(Data())
        }

        plugin.responders.uploadData = { _, _, _, _ in
            .failure(.unknown("Test"))
        }

        plugin.responders.getURL = { _, _ in
            .success(URL(fileURLWithPath: "file:///path/to/file"))
        }

        let sink = Amplify.Storage.downloadData(key: "key")
            .flatMap { data in
                Amplify.Storage.uploadData(key: "key2", data: data)
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
