//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import XCTest
import Combine
@testable import AWSAPIPlugin

class AppSyncRealTimeClientTests: XCTestCase {

    func testSendRequestWithTimeout_withNoResponse_failedWithTimeOutError() async {
        let timeout = 1.0
        let dataSource = PassthroughSubject<AppSyncRealTimeResponse, Never>()
        let requestFactoryExpectation = expectation(description: "Request factory being called")
        let requestFailedExpectation = expectation(description: "Request should be failed with error")
        Task {
            do {
                try await AppSyncRealTimeClient.sendRequestWithTimeout(
                    timeout,
                    on: dataSource.eraseToAnyPublisher(),
                    filter: { _ in true }) {
                        requestFactoryExpectation.fulfill()
                    }
                XCTFail("The operation should be failed with time out")
            } catch {
                let requestError = error as! AppSyncRealTimeRequest.Error
                XCTAssert(requestError == .timeout)
                requestFailedExpectation.fulfill()
            }
        }
        await fulfillment(of: [requestFactoryExpectation, requestFailedExpectation], timeout: timeout + 1)
    }

    func testSendRequestWithTimeout_withCorrectResponse_succeed() async {
        let timeout = 1.0
        let dataSource = PassthroughSubject<AppSyncRealTimeResponse, Never>()
        let requestFactoryExpectation = expectation(description: "Request factory being called")
        let finishExpectation = expectation(description: "Request finished successfully")
        Task {
            do {
                try await AppSyncRealTimeClient.sendRequestWithTimeout(
                    timeout,
                    on: dataSource.eraseToAnyPublisher(),
                    filter: { $0.type == .connectionAck }) {
                        requestFactoryExpectation.fulfill()
                        dataSource.send(.init(id: nil, payload: nil, type: .connectionAck))
                    }
                finishExpectation.fulfill()
            } catch {
                XCTFail("Operation shouldn't fail with error \(error)")
            }
        }
        await fulfillment(of: [requestFactoryExpectation, finishExpectation], timeout: timeout + 1)
    }

    func testSendRequestWithTimeout_withErrorResponse_transformLimitExceededError() async {
        let timeout = 1.0
        let dataSource = PassthroughSubject<AppSyncRealTimeResponse, Never>()
        let requestFactoryExpectation = expectation(description: "Request factory being called")
        let limitExceededErrorExpectation = expectation(description: "Request should be failed with limitExceeded error")
        let id = UUID().uuidString
        Task {
            do {
                try await AppSyncRealTimeClient.sendRequestWithTimeout(
                    timeout,
                    id: id,
                    on: dataSource.eraseToAnyPublisher(),
                    filter: { $0.type == .connectionAck }) {
                        requestFactoryExpectation.fulfill()
                        dataSource.send(.init(
                            id: id,
                            payload: .object([
                                "errors": .array([
                                    .object([
                                        "errorType": "LimitExceededError"
                                    ])
                                ])
                            ]),
                            type: .error
                        ))
                    }
                XCTFail("Operation should be failed")
            } catch {
                let requestError = error as! AppSyncRealTimeRequest.Error
                XCTAssertEqual(requestError, .limitExceeded)
                limitExceededErrorExpectation.fulfill()
            }
        }
        await fulfillment(of: [requestFactoryExpectation, limitExceededErrorExpectation], timeout: timeout + 1)
    }

    func testSendRequestWithTimeout_withErrorResponse_transformMaxSubscriptionsReachedError() async {
        let timeout = 1.0
        let dataSource = PassthroughSubject<AppSyncRealTimeResponse, Never>()
        let requestFactoryExpectation = expectation(description: "Request factory being called")
        let maxSubscriptionsReachedExpectation =
            expectation(description: "Request should be failed with maxSubscriptionsReached error")
        let id = UUID().uuidString
        Task {
            do {
                try await AppSyncRealTimeClient.sendRequestWithTimeout(
                    timeout,
                    id: id,
                    on: dataSource.eraseToAnyPublisher(),
                    filter: { $0.type == .connectionAck }) {
                        requestFactoryExpectation.fulfill()
                        dataSource.send(.init(
                            id: id,
                            payload: .object([
                                "errors": .array([
                                    .object([
                                        "errorType": "MaxSubscriptionsReachedError"
                                    ])
                                ])
                            ]),
                            type: .error
                        ))
                    }
                XCTFail("Operation should be failed")
            } catch {
                let requestError = error as! AppSyncRealTimeRequest.Error
                XCTAssertEqual(requestError, .maxSubscriptionsReached)
                maxSubscriptionsReachedExpectation.fulfill()
            }
        }
        await fulfillment(of: [
            requestFactoryExpectation,
            maxSubscriptionsReachedExpectation
        ], timeout: timeout + 1)
    }
}
