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

@available(iOS 13.0, *)
class AmplifyOperationCombineTests: XCTestCase {

    func testResultPublisherSucceeds() {
        let responder: MockPublisherOperation.Responder = { operation in
            operation.dispatch(result: .success(1))
            operation.finish()
        }

        let receivedValue = expectation(description: "Received value")
        let receivedFinished = expectation(description: "Received finished")
        let receivedFailure = expectation(description: "Received failure")
        receivedFailure.isInverted = true

        let operation = MockPublisherOperation(responder: responder)
        let sink = operation
            .internalResultPublisher
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    receivedFailure.fulfill()
                case .finished:
                    receivedFinished.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        operation.main()

        waitForExpectations(timeout: 0.05)
        sink.cancel()
    }

    func testResultPublisherFails() {
        let responder: MockPublisherOperation.Responder = { operation in
            operation.dispatch(result: .failure(.unknown("Test", "Test")))
            operation.finish()
        }

        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedFinished = expectation(description: "Received finished")
        receivedFinished.isInverted = true
        let receivedFailure = expectation(description: "Received failure")

        let operation = MockPublisherOperation(responder: responder)
        let sink = operation
            .internalResultPublisher
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    receivedFailure.fulfill()
                case .finished:
                    receivedFinished.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        operation.main()

        waitForExpectations(timeout: 0.05)
        sink.cancel()
    }

    func testResultPublisherCancels() {
        let responder: MockPublisherOperation.Responder = { operation in
            operation.dispatch(result: .success(1))
            operation.finish()
        }

        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedFinished = expectation(description: "Received finished")
        let receivedFailure = expectation(description: "Received failure")
        receivedFailure.isInverted = true

        let operation = MockPublisherOperation(responder: responder)
        let sink = operation
        .internalResultPublisher
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    receivedFailure.fulfill()
                case .finished:
                    receivedFinished.fulfill()
                }
            }, receiveValue: { _ in
                receivedValue.fulfill()
            })

        operation.cancel()

        waitForExpectations(timeout: 0.05)
        sink.cancel()
    }

    func testChainedResultPublishersSucceed() {
        let makeSuccessResponder: (Int) -> MockPublisherOperation.Responder = { value in
            let successResponder: MockPublisherOperation.Responder = { operation in
                operation.dispatch(result: .success(value))
                operation.finish()
            }
            return successResponder
        }

        let receivedValue = expectation(description: "Received value")
        let receivedFinished = expectation(description: "Received finished")
        let receivedFailure = expectation(description: "Received failure")
        receivedFailure.isInverted = true

        let mockOp1 = MockPublisherOperation(responder: makeSuccessResponder(1))
        let mockOp2 = MockPublisherOperation(responder: makeSuccessResponder(2))

        let sink = Publishers.Zip(
            mockOp1.internalResultPublisher,
            mockOp2.internalResultPublisher
        ).flatMap { (value1: Int, value2: Int) -> AnyPublisher<Int, APIError> in
            let mockOp = MockPublisherOperation(responder: makeSuccessResponder(value1 + value2))
            mockOp.main()
            return mockOp.internalResultPublisher
        }.flatMap { (value: Int) -> AnyPublisher<Int, APIError> in
            let mockOp = MockPublisherOperation(responder: makeSuccessResponder(value + 1))
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
        let makeSuccessResponder: (Int) -> MockPublisherOperation.Responder = { value in
            let successResponder: MockPublisherOperation.Responder = { operation in
                operation.dispatch(result: .success(value))
                operation.finish()
            }
            return successResponder
        }

        let failureResponder: MockPublisherOperation.Responder = { operation in
            operation.dispatch(result: .failure(.unknown("Test", "Test")))
            operation.finish()
        }

        let receivedValue = expectation(description: "Received value")
        receivedValue.isInverted = true
        let receivedFinished = expectation(description: "Received finished")
        receivedFinished.isInverted = true
        let receivedFailure = expectation(description: "Received failure")

        let mockOp1 = MockPublisherOperation(responder: makeSuccessResponder(1))
        let mockOp2 = MockPublisherOperation(responder: makeSuccessResponder(2))

        let sink = Publishers.Zip(
            mockOp1.internalResultPublisher,
            mockOp2.internalResultPublisher
        ).flatMap { (_, _) -> AnyPublisher<Int, APIError> in
            let mockOp = MockPublisherOperation(responder: failureResponder)
            mockOp.main()
            return mockOp.internalResultPublisher
        }.flatMap { (value: Int) -> AnyPublisher<Int, APIError> in
            let mockOp = MockPublisherOperation(responder: makeSuccessResponder(value + 1))
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
        let makeSuccessResponder: (Int) -> MockPublisherOperation.Responder = { value in
            let successResponder: MockPublisherOperation.Responder = { operation in
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

        let mockOp1 = MockPublisherOperation(responder: makeSuccessResponder(1))
        let mockOp2 = MockPublisherOperation(responder: makeSuccessResponder(2))

        let sink = Publishers.Zip(
            mockOp1.internalResultPublisher,
            mockOp2.internalResultPublisher
        ).flatMap { (value1: Int, value2: Int) -> AnyPublisher<Int, APIError> in
            let mockOp = MockPublisherOperation(responder: makeSuccessResponder(value1 + value2))
            mockOp.cancel()
            return mockOp.internalResultPublisher
        }.flatMap { (value: Int) -> AnyPublisher<Int, APIError> in
            let mockOp = MockPublisherOperation(responder: makeSuccessResponder(value + 1))
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

}

struct MockPublisherRequest: AmplifyOperationRequest {
    struct Options { }
    let options = Options()
}

extension HubPayloadEventName {
    static var mockPublisherOperation = "MockPublisherOperation"
}

class MockPublisherOperation: AmplifyOperation<MockPublisherRequest, Int, APIError> {
    typealias Responder = (MockPublisherOperation) -> Void
    let responder: Responder

    init(responder: @escaping Responder, resultListener: ResultListener? = nil) {
        self.responder = responder
        super.init(
            categoryType: .api,
            eventName: .mockPublisherOperation,
            request: MockPublisherRequest(),
            resultListener: resultListener
        )
    }

    override func main() {
        DispatchQueue.global().async {
            self.responder(self)
        }
    }

}
#endif
