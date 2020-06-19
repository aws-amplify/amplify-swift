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

class APIGraphQLGeneralTests: XCTestCase {

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

    func testQuerySucceeds() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true

        let responder = QueryRequestListenerResponder<String> { _, listener in
            listener?(self.successfulResultEvent)
            return nil
        }
        plugin.responders[.queryRequestListener] = responder

        let sink = Amplify.API.query(request: GraphQLRequest(document: "", responseType: String.self))
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

    func testQueryFails() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")

        let responder = QueryRequestListenerResponder<String> { _, listener in
            listener?(self.failureResultEvent)
            return nil
        }
        plugin.responders[.queryRequestListener] = responder

        let sink = Amplify.API.query(request: GraphQLRequest(document: "", responseType: String.self))
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

    func testMutateSucceeds() {
        let receivedValue = expectation(description: "Received value")
        let receivedError = expectation(description: "Received error")
        receivedError.isInverted = true

        let responder = MutateRequestListenerResponder<String> { _, listener in
            listener?(self.successfulResultEvent)
            return nil
        }
        plugin.responders[.mutateRequestListener] = responder

        let sink = Amplify.API.mutate(request: GraphQLRequest(document: "", responseType: String.self))
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

    func testMutateFails() {
        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedError = expectation(description: "Received error")

        let responder = MutateRequestListenerResponder<String> { _, listener in
            listener?(self.failureResultEvent)
            return nil
        }
        plugin.responders[.mutateRequestListener] = responder

        let sink = Amplify.API.mutate(request: GraphQLRequest(document: "", responseType: String.self))
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

    func testSubscribeReceivesConnectionEvent() {
        let receivedValue = expectation(description: "Received connection value")

        let responder = SubscribeRequestListenerResponder<String> { _, inProcessListener, _ in
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(10)) {
                let event = SubscriptionEvent<GraphQLResponse<String>>.connection(.connected)
                inProcessListener?(event)
            }
            return nil
        }
        plugin.responders[.subscribeRequestListener] = responder

        let sink = Amplify.API.subscribe(request: GraphQLRequest(document: "", responseType: String.self))
            .sink(receiveCompletion: { _ in },
                  receiveValue: { event in
                    switch event {
                    case .connection:
                        receivedValue.fulfill()
                    case .data:
                        break
                    }
            })

        waitForExpectations(timeout: 1.0)
        sink.cancel()
    }

    func testSubscribeReceivesSuccessfulDataEvent() {
        let receivedValue = expectation(description: "Received successful data value")

        let responder = SubscribeRequestListenerResponder<String> { _, inProcessListener, _ in
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(10)) {
                let event = SubscriptionEvent<GraphQLResponse<String>>.data(.success("Test"))
                inProcessListener?(event)
            }
            return nil
        }
        plugin.responders[.subscribeRequestListener] = responder

        let sink = Amplify.API.subscribe(request: GraphQLRequest(document: "", responseType: String.self))
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { event in
                    switch event {
                    case .connection:
                        break
                    case .data(let event):
                        switch event {
                        case .failure:
                            break
                        case .success:
                            receivedValue.fulfill()
                        }
                    }
            })

        waitForExpectations(timeout: 1.0)
        sink.cancel()
    }

    func testSubscribeReceivesFailureDataEvent() {
        let receivedValue = expectation(description: "Received failure data value")

        let responder = SubscribeRequestListenerResponder<String> { _, inProcessListener, _ in
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(10)) {
                let event = SubscriptionEvent<GraphQLResponse<String>>.data(.failure(.partial("Test", [])))
                inProcessListener?(event)
            }
            return nil
        }
        plugin.responders[.subscribeRequestListener] = responder

        let sink = Amplify.API.subscribe(request: GraphQLRequest(document: "", responseType: String.self))
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { event in
                    switch event {
                    case .connection:
                        break
                    case .data(let event):
                        switch event {
                        case .failure:
                            receivedValue.fulfill()
                        case .success:
                            break
                        }
                    }
            })

        waitForExpectations(timeout: 1.0)
        sink.cancel()
    }

    func testSubscribeReceivesSuccessfulCompletion() {
        let receivedCompletion = expectation(description: "Received successful completion")

        let responder = SubscribeRequestListenerResponder<String> { _, _, resultListener in
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(10)) {
                resultListener?(.successfulVoid)
            }
            return nil
        }
        plugin.responders[.subscribeRequestListener] = responder

        let sink = Amplify.API.subscribe(request: GraphQLRequest(document: "", responseType: String.self))
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        receivedCompletion.fulfill()
                    case .failure:
                        break
                    }
            }, receiveValue: { _ in }
        )

        waitForExpectations(timeout: 1.0)
        sink.cancel()
    }

    func testSubscribeReceivesFailureCompletion() {
        let receivedCompletion = expectation(description: "Received failure completion")

        let responder = SubscribeRequestListenerResponder<String> { _, _, resultListener in
            DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(10)) {
                resultListener?(.failure(.unknown("Test", "test")))
            }
            return nil
        }
        plugin.responders[.subscribeRequestListener] = responder

        let sink = Amplify.API.subscribe(request: GraphQLRequest(document: "", responseType: String.self))
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        break
                    case .failure:
                        receivedCompletion.fulfill()
                    }
            }, receiveValue: { _ in }
        )

        waitForExpectations(timeout: 1.0)
        sink.cancel()
    }

}
