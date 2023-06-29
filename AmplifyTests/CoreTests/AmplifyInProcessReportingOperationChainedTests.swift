//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(Combine)
import XCTest
import Combine

@testable import Amplify
@testable import AmplifyTestCommon

// swiftlint:disable:next type_name
class AmplifyInProcessReportingOperationChainedTests: XCTestCase {

    func testChainedResultPublishersSucceed() {
        let makeSuccessResponder: (Int) -> MockPublisherInProcessOperation.Responder = { value in
            let successResponder: MockPublisherInProcessOperation.Responder = { operation in
                operation.dispatch(result: .success(value))
                operation.finish()
            }
            return successResponder
        }

        let receivedValue = expectation(description: "Received value")
        let receivedFinished = expectation(description: "Received finished")
        let receivedFailure = expectation(description: "Received failure")
        receivedFailure.isInverted = true

        let mockOp1 = MockPublisherInProcessOperation(responder: makeSuccessResponder(1))
        let mockOp2 = MockPublisherInProcessOperation(responder: makeSuccessResponder(2))

        let sink = Publishers.Zip(
            mockOp1.internalResultPublisher,
            mockOp2.internalResultPublisher
        ).flatMap { (value1: Int, value2: Int) -> AnyPublisher<Int, APIError> in
            let mockOp = MockPublisherInProcessOperation(responder: makeSuccessResponder(value1 + value2))
            mockOp.main()
            return mockOp.internalResultPublisher
        }.flatMap { (value: Int) -> AnyPublisher<Int, APIError> in
            let mockOp = MockPublisherInProcessOperation(responder: makeSuccessResponder(value + 1))
            mockOp.main()
            return mockOp.internalResultPublisher
        }.sink(receiveCompletion: { completion in
            switch completion {
            case .failure:
                receivedFailure.fulfill()
            case .finished:
                receivedFinished.fulfill()
            }
        }, receiveValue: { _ in
            receivedValue.fulfill()
        })

        mockOp1.main()
        mockOp2.main()

        waitForExpectations(timeout: 0.05)
        sink.cancel()
    }

    func testChainedResultPublishersFail() {
        let makeSuccessResponder: (Int) -> MockPublisherInProcessOperation.Responder = { value in
            let successResponder: MockPublisherInProcessOperation.Responder = { operation in
                operation.dispatch(result: .success(value))
                operation.finish()
            }
            return successResponder
        }

        let failureResponder: MockPublisherInProcessOperation.Responder = { operation in
            operation.dispatch(result: .failure(.unknown("Test", "Test")))
            operation.finish()
        }

        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedFinished = expectation(description: "Received finished")
        receivedFinished.isInverted = true
        let receivedFailure = expectation(description: "Received failure")

        let mockOp1 = MockPublisherInProcessOperation(responder: makeSuccessResponder(1))
        let mockOp2 = MockPublisherInProcessOperation(responder: makeSuccessResponder(2))

        let sink = Publishers.Zip(
            mockOp1.internalResultPublisher,
            mockOp2.internalResultPublisher
        ).flatMap { (_, _) -> AnyPublisher<Int, APIError> in
            let mockOp = MockPublisherInProcessOperation(responder: failureResponder)
            mockOp.main()
            return mockOp.internalResultPublisher
        }.flatMap { (value: Int) -> AnyPublisher<Int, APIError> in
            let mockOp = MockPublisherInProcessOperation(responder: makeSuccessResponder(value + 1))
            mockOp.main()
            return mockOp.internalResultPublisher
        }.sink(receiveCompletion: { completion in
            switch completion {
            case .failure:
                receivedFailure.fulfill()
            case .finished:
                receivedFinished.fulfill()
            }
        }, receiveValue: { _ in
            receivedValue.fulfill()
        })

        mockOp1.main()
        mockOp2.main()

        waitForExpectations(timeout: 0.05)
        sink.cancel()
    }

    func testChainedResultPublishersCancel() {
        let makeSuccessResponder: (Int) -> MockPublisherInProcessOperation.Responder = { value in
            let successResponder: MockPublisherInProcessOperation.Responder = { operation in
                operation.dispatch(result: .success(value))
                operation.finish()
            }
            return successResponder
        }

        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedFinished = expectation(description: "Received finished")
        let receivedFailure = expectation(description: "Received failure")
        receivedFailure.isInverted = true

        let mockOp1 = MockPublisherInProcessOperation(responder: makeSuccessResponder(1))
        let mockOp2 = MockPublisherInProcessOperation(responder: makeSuccessResponder(2))

        let sink = Publishers.Zip(
            mockOp1.internalResultPublisher,
            mockOp2.internalResultPublisher
        ).flatMap { (value1: Int, value2: Int) -> AnyPublisher<Int, APIError> in
            let mockOp = MockPublisherInProcessOperation(responder: makeSuccessResponder(value1 + value2))
            mockOp.cancel()
            return mockOp.internalResultPublisher
        }.flatMap { (value: Int) -> AnyPublisher<Int, APIError> in
            let mockOp = MockPublisherInProcessOperation(responder: makeSuccessResponder(value + 1))
            mockOp.main()
            return mockOp.internalResultPublisher
        }.sink(receiveCompletion: { completion in
            switch completion {
            case .failure:
                receivedFailure.fulfill()
            case .finished:
                receivedFinished.fulfill()
            }
        }, receiveValue: { _ in
            receivedValue.fulfill()
        })

        mockOp1.main()
        mockOp2.main()

        waitForExpectations(timeout: 1)
        sink.cancel()
    }

}
#endif
