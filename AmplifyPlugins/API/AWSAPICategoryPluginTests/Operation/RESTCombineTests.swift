//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSAPIPlugin
@testable import AmplifyTestCommon

@available(iOS 13.0, *)
class RESTCombineTests: OperationTestBase {

    func testGetSucceeds() throws {
        let sentData = Data([0x00, 0x01, 0x02, 0x03])
        try setUpPluginForSingleResponse(sending: sentData, for: .graphQL)

        let request = RESTRequest(apiName: "Valid", path: "/path")

        let receivedValue = expectation(description: "Received value")
        let receivedFinish = expectation(description: "Received finished")
        let receivedFailure = expectation(description: "Received failed")
        receivedFailure.isInverted = true

        let sink = apiPlugin.get(request: request)
            .resultPublisher
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    receivedFailure.fulfill()
                case .finished:
                    receivedFinish.fulfill()
                }
            }, receiveValue: { value in
                XCTAssertEqual(value, sentData)
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
        sink.cancel()
    }

    func testGetFails() throws {
        let sentData = Data([0x00, 0x01, 0x02, 0x03])
        try setUpPluginForSingleError(for: .graphQL)

        let request = RESTRequest(apiName: "Valid", path: "/path")

        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedFinish = expectation(description: "Received finished")
        receivedFinish.isInverted = true
        let receivedFailure = expectation(description: "Received failed")

        let sink = apiPlugin.get(request: request)
            .resultPublisher
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    receivedFailure.fulfill()
                case .finished:
                    receivedFinish.fulfill()
                }
            }, receiveValue: { value in
                XCTAssertEqual(value, sentData)
                receivedValue.fulfill()
            })

        waitForExpectations(timeout: 0.05)
        sink.cancel()
    }

    func testGetCancels() throws {
        let sentData = Data([0x00, 0x01, 0x02, 0x03])
        try setUpPluginForSingleResponse(sending: sentData, for: .graphQL)

        let request = RESTRequest(apiName: "Valid", path: "/path")

        let receivedFinish = expectation(description: "Received finished")
        let receivedFailure = expectation(description: "Received failed")
        receivedFailure.isInverted = true

        let operation = apiPlugin.get(request: request)

        let sink = operation
            .resultPublisher
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    receivedFailure.fulfill()
                case .finished:
                    receivedFinish.fulfill()
                }
            }, receiveValue: { _ in })

        DispatchQueue.global().async {
            operation.cancel()
        }

        waitForExpectations(timeout: 1.05)
        sink.cancel()
    }

}
