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

class APIGraphQLChainTests: XCTestCase {

    var plugin: MockAPICategoryPlugin!

    // Easy access to result-style events (for query & mutate operations)
    let successfulResultEvent = GraphQLOperation<String>.OperationResult.success(.success("Test"))
    let failureResultEvent = GraphQLOperation<String>.OperationResult.failure(
        APIError.unknown("Test", "Test")
    )

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

        let queryResponder = QueryRequestListenerResponder<String> { _, listener in
            listener?(self.successfulResultEvent)
            return nil
        }
        plugin.responders[.queryRequestListener] = queryResponder

        let mutateResponder = MutateRequestListenerResponder<String> { _, listener in
            listener?(self.successfulResultEvent)
            return nil
        }
        plugin.responders[.mutateRequestListener] = mutateResponder

        let sink = Amplify.API.query(request: GraphQLRequest(document: "", responseType: String.self))
            .flatMap { _ in
                Amplify.API.mutate(request: GraphQLRequest(document: "", responseType: String.self))
        }.flatMap { _ in
            Amplify.API.query(request: GraphQLRequest(document: "", responseType: String.self))
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

        let queryResponder = QueryRequestListenerResponder<String> { _, listener in
            listener?(self.successfulResultEvent)
            return nil
        }
        plugin.responders[.queryRequestListener] = queryResponder

        let mutateResponder = MutateRequestListenerResponder<String> { _, listener in
            listener?(self.failureResultEvent)
            return nil
        }
        plugin.responders[.mutateRequestListener] = mutateResponder

        let sink = Amplify.API.query(request: GraphQLRequest(document: "", responseType: String.self))
            .flatMap { _ in
                Amplify.API.mutate(request: GraphQLRequest(document: "", responseType: String.self))
        }.flatMap { _ in
            Amplify.API.query(request: GraphQLRequest(document: "", responseType: String.self))
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
