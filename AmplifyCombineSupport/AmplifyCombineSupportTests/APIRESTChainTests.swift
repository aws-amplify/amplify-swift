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

class APIRESTChainTests: XCTestCase {

    var plugin: MockAPICategoryPlugin!

    override func setUpWithError() throws {
        Amplify.reset()

        let categoryConfig = APICategoryConfiguration(
            plugins: ["MockAPICategoryPlugin": true]
        )

        let amplifyConfig = AmplifyConfiguration(api: categoryConfig)
        plugin = MockAPICategoryPlugin()
        try Amplify.add(plugin: plugin)
        try Amplify.configure(amplifyConfig)
    }

    func testChainedOperationsSucceed() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true

        plugin.restResponders.head = { _ in
            .success(Data())
        }

        plugin.restResponders.get = { _ in
            .success(Data())
        }

        plugin.restResponders.put = { _ in
            .success(Data())
        }

        let sink = Amplify.API.head(request: RESTRequest())
            .flatMap { _ in
                Amplify.API.get(request: RESTRequest())
        }.flatMap { _ in
            Amplify.API.put(request: RESTRequest())
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

        plugin.restResponders.head = { _ in
            .success(Data())
        }

        plugin.restResponders.get = { _ in
            .failure(.unknown("Test", "Test"))
        }

        plugin.restResponders.put = { _ in
            .success(Data())
        }

        let sink = Amplify.API.head(request: RESTRequest())
            .flatMap { _ in
                Amplify.API.get(request: RESTRequest())
        }.flatMap { _ in
            Amplify.API.put(request: RESTRequest())
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
