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

class StorageGeneralTests: XCTestCase {

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
        plugin.responders.getURL = { _, _ in
            .success(URL(fileURLWithPath: "file:///path/to/file"))
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
        plugin.responders.getURL = { _, _ in
            .failure(.unknown("Test"))
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

    func testDownloadFileSucceeds() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true
        plugin.responders.downloadFile = { _, _, _, _ in
            .successfulVoid
        }
        _ = Amplify.Storage.downloadFile(key: "key", local: URL(fileURLWithPath: "file:///path/to/file"))
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    receivedError.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
    }

    func testDownloadFileFails() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")
        plugin.responders.downloadFile = { _, _, _, _ in
            .failure(.unknown("Test"))
        }
        _ = Amplify.Storage.downloadFile(key: "key", local: URL(fileURLWithPath: "file:///path/to/file"))
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    receivedError.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
    }

    func testUploadDataSucceeds() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true
        plugin.responders.uploadData = { _, _, _, _ in
            .success("Test")
        }
        _ = Amplify.Storage.uploadData(key: "key", data: Data())
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    receivedError.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
    }

    func testUploadDataFails() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")
        plugin.responders.uploadData = { _, _, _, _ in
            .failure(.unknown("Test"))
        }
        _ = Amplify.Storage.uploadData(key: "key", data: Data())
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    receivedError.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
    }

    func testUploadFileSucceeds() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true
        plugin.responders.uploadFile = { _, _, _, _ in
            .success("Test")
        }
        _ = Amplify.Storage.uploadFile(key: "key", local: URL(fileURLWithPath: "file:///path/to/file"))
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    receivedError.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
    }

    func testUploadFileFails() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")
        plugin.responders.uploadFile = { _, _, _, _ in
            .failure(.unknown("Test"))
        }
        _ = Amplify.Storage.uploadFile(key: "key", local: URL(fileURLWithPath: "file:///path/to/file"))
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
        plugin.responders.remove = { _, _ in
            .success("Test")
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
        plugin.responders.remove = { _, _ in
            .failure(.unknown("Test"))
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
        plugin.responders.list = { _ in
            .success(StorageListResult(items: []))
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
        plugin.responders.list = { _ in
            .failure(.unknown("Test"))
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
