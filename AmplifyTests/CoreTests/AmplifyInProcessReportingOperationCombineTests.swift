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
class AmplifyInProcessReportingOperationCombineTests: XCTestCase {

    var receivedResultValue: XCTestExpectation!
    var receivedResultFinished: XCTestExpectation!
    var receivedResultFailure: XCTestExpectation!

    var receivedInProcessValue: XCTestExpectation!
    var receivedInProcessFinished: XCTestExpectation!
    var receivedInProcessFailure: XCTestExpectation!

    var resultSink: AnyCancellable?
    var inProcessSink: AnyCancellable?

    override func setUp() async throws {
        receivedResultValue = expectation(description: "receivedResultValue")
        receivedResultFinished = expectation(description: "receivedResultFinished")
        receivedResultFailure = expectation(description: "receivedResultFailure")

        receivedInProcessValue = expectation(description: "receivedInProcessValue")
        receivedInProcessFinished = expectation(description: "receivedInProcessFinished")

        // The in-process publisher has a Failure type of `Never`,
        // so we expect it to never be fulfilled
        receivedInProcessFailure = expectation(description: "receivedInProcessFailure")
        receivedInProcessFailure.isInverted = true
    }

    func testResultPublisherSucceeds() {
        let responder: MockPublisherInProcessOperation.Responder = { operation in
            operation.dispatchInProcess(data: "One")
            operation.dispatch(result: .success(1))
            operation.finish()
        }

        receivedResultFailure.isInverted = true
        receivedInProcessFailure.isInverted = true

        let operation = makeOperation(using: responder)
        operation.main()

        waitForExpectations(timeout: 0.05)
    }

    func testResultPublisherFails() {
        let responder: MockPublisherInProcessOperation.Responder = { operation in
            operation.dispatchInProcess(data: "One")
            operation.dispatch(result: .failure(.unknown("Test", "Test")))
            operation.finish()
        }

        receivedResultFinished.isInverted = true
        receivedResultValue.isInverted = true

        let operation = makeOperation(using: responder)
        operation.main()

        waitForExpectations(timeout: 0.05)
    }

    func testResultPublisherCancels() {
        let responder: MockPublisherInProcessOperation.Responder = { operation in
            operation.dispatchInProcess(data: "One")
            operation.dispatch(result: .success(1))
            operation.finish()
        }

        receivedResultFailure.isInverted = true
        receivedInProcessFailure.isInverted = true
        receivedResultValue.isInverted = true
        receivedInProcessValue.isInverted = true

        let operation = makeOperation(using: responder)
        operation.cancel()

        waitForExpectations(timeout: 0.05)
    }

    func makeOperation(
        using responder: @escaping MockPublisherInProcessOperation.Responder
    ) -> MockPublisherInProcessOperation {
        let operation = MockPublisherInProcessOperation(responder: responder)
        resultSink = operation
            .internalResultPublisher
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    self.receivedResultFailure.fulfill()
                case .finished:
                    self.receivedResultFinished.fulfill()
                }
            }, receiveValue: { _ in
                self.receivedResultValue.fulfill()
            })

        inProcessSink = operation
            .internalInProcessPublisher
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure:
                    self.receivedInProcessFailure.fulfill()
                case .finished:
                    self.receivedInProcessFinished.fulfill()
                }
            }, receiveValue: { _ in
                self.receivedInProcessValue.fulfill()
            })

        return operation
    }

}

extension HubPayloadEventName {
    static var mockPublisherInProcessReportingOperation = "mockPublisherInProcessReportingOperation"
}

class MockPublisherInProcessOperation: AmplifyInProcessReportingOperation<
    MockPublisherRequest,
    String,
    Int,
    APIError
> {
    typealias Responder = (MockPublisherInProcessOperation) -> Void
    let responder: Responder

    init(responder: @escaping Responder, resultListener: ResultListener? = nil) {
        self.responder = responder
        super.init(
            categoryType: .api,
            eventName: .mockPublisherInProcessReportingOperation,
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
