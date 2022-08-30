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

class RESTCombineTests: OperationTestBase {

    func testGetSucceeds() throws {
        let sentData = Data([0x00, 0x01, 0x02, 0x03])
        try setUpPluginForSingleResponse(sending: sentData, for: .graphQL)

        let request = RESTRequest(apiName: "Valid", path: "/path")

        let receivedValue = expectation(description: "Received value")
        let receivedFinish = expectation(description: "Received finished")
        let receivedFailure = expectation(description: "Received failed")
        receivedFailure.isInverted = true
        
        let sink = Amplify.Publisher.create {
            try await self.apiPlugin.get(request: request)
        }.sink(receiveCompletion: { completion in
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

        let sink = Amplify.Publisher.create {
            try await self.apiPlugin.get(request: request)
        }.sink(receiveCompletion: { completion in
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
}
