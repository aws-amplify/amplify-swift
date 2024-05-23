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

class GraphQLQueryCombineTests: OperationTestBase {
    let testDocument = "query { getTodo { id name description }}"

    func testQuerySucceeds() async throws {
        let testJSONData: JSONValue = ["foo": true]
        let sentData = Data(#"{"data": {"foo": true}}"#.utf8)
        try setUpPluginForSingleResponse(sending: sentData, for: .graphQL)

        let request = GraphQLRequest(document: testDocument, variables: nil, responseType: JSONValue.self)

        let receivedValue = expectation(description: "Received value")
        let receivedResponseError = expectation(description: "Received response error")
        receivedResponseError.isInverted = true
        let receivedFinish = expectation(description: "Received finished")
        let receivedFailure = expectation(description: "Received failed")
        receivedFailure.isInverted = true

        let sink = Amplify.Publisher.create {
            try await self.apiPlugin.query(request: request)
        }.sink(receiveCompletion: { completion in
            switch completion {
            case .failure:
                receivedFailure.fulfill()
            case .finished:
                receivedFinish.fulfill()
            }
        }, receiveValue: { queryResult in
            switch queryResult {
            case .success(let jsonValue):
                XCTAssertEqual(jsonValue, testJSONData)
                receivedValue.fulfill()
            case .failure:
                receivedResponseError.fulfill()
            }
        })
        
        await fulfillment(of: [receivedValue,
                               receivedFinish,
                               receivedFailure,
                               receivedResponseError
                              ],
                          timeout: 0.05)
        sink.cancel()
    }

    func testQueryHandlesResponseError() async throws {
        let sentData = Data(#"{"data": {"foo": true}, "errors": []}"#.utf8)
        try setUpPluginForSingleResponse(sending: sentData, for: .graphQL)

        let request = GraphQLRequest(document: testDocument, variables: nil, responseType: JSONValue.self)

        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedResponseError = expectation(description: "Received response error")
        let receivedFinish = expectation(description: "Received finished")
        let receivedFailure = expectation(description: "Received failed")
        receivedFailure.isInverted = true

        let sink = Amplify.Publisher.create {
            try await self.apiPlugin.query(request: request)
        }.sink(receiveCompletion: { completion in
            switch completion {
            case .failure:
                receivedFailure.fulfill()
            case .finished:
                receivedFinish.fulfill()
            }
        }, receiveValue: { queryResult in
            switch queryResult {
            case .success:
                receivedValue.fulfill()
            case .failure:
                receivedResponseError.fulfill()
            }
        })
        
        await fulfillment(of: [receivedValue,
                               receivedFinish,
                               receivedFailure,
                               receivedResponseError
                              ],
                          timeout: 0.05)
        sink.cancel()

    }

    func testQueryFails() async throws {
        try setUpPluginForSingleError(for: .graphQL)

        let request = GraphQLRequest(document: testDocument, variables: nil, responseType: JSONValue.self)

        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedResponseError = expectation(description: "Received response error")
        receivedResponseError.isInverted = true
        let receivedFinish = expectation(description: "Received finished")
        receivedFinish.isInverted = true
        let receivedFailure = expectation(description: "Received failed")
        
        let sink = Amplify.Publisher.create {
            try await self.apiPlugin.query(request: request)
        }.sink(receiveCompletion: { completion in
            switch completion {
            case .failure:
                receivedFailure.fulfill()
            case .finished:
                receivedFinish.fulfill()
            }
        }, receiveValue: { queryResult in
            switch queryResult {
            case .success:
                receivedValue.fulfill()
            case .failure:
                receivedResponseError.fulfill()
            }
        })

        await fulfillment(of: [receivedValue,
                               receivedFinish,
                               receivedFailure,
                               receivedResponseError
                              ],
                          timeout: 0.05)
        sink.cancel()
    }
}
