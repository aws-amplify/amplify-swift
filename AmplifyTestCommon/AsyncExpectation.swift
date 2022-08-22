//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import Amplify

public actor AsyncExpectation {
    enum State {
        case pending
        case fulfilled
        case timedOut
    }
    public typealias AsyncExpectationContinuation = CheckedContinuation<Void, Error>
    public let expectationDescription: String
    public let isInverted: Bool
    public let expectedFulfillmentCount: Int

    private var fulfillmentCount: Int = 0
    private var continuation: AsyncExpectationContinuation?
    private var state: State = .pending

    public var isFulfilled: Bool {
        state == .fulfilled
    }

    public init(description: String,
                isInverted: Bool = false,
                expectedFulfillmentCount: Int = 1) {
        expectationDescription = description
        self.isInverted = isInverted
        self.expectedFulfillmentCount = expectedFulfillmentCount
    }

    /// Marks the expectation as having been met.
    ///
    /// It is an error to call this method on an expectation that has already been fulfilled,
    /// or when the test case that vended the expectation has already completed.
    public func fulfill(file: StaticString = #filePath, line: UInt = #line) {
        guard state != .fulfilled else { return }

        if isInverted {
            if state != .timedOut {
                XCTFail("Inverted expectation fulfilled: \(expectationDescription)", file: file, line: line)
                state = .fulfilled
                finish()
            }
            return
        }

        fulfillmentCount += 1
        if fulfillmentCount == expectedFulfillmentCount {
            state = .fulfilled
            finish()
        }
    }

    internal nonisolated func wait() async throws {
        try await withTaskCancellationHandler(handler: {
            Task {
                await cancel()
            }
        }, operation: {
            try await handleWait()
        })
    }

    internal func timeOut(file: StaticString = #filePath,
                          line: UInt = #line) async {
        if isInverted {
            state = .timedOut
        } else if state != .fulfilled {
            state = .timedOut
            XCTFail("Expectation timed out: \(expectationDescription)", file: file, line: line)
        }
        finish()
    }

    private func handleWait() async throws {
        if state == .fulfilled {
            return
        } else {
            try await withCheckedThrowingContinuation { (continuation: AsyncExpectationContinuation) in
                self.continuation = continuation
            }
        }
    }

    private func cancel() {
        continuation?.resume(throwing: CancellationError())
        continuation = nil
    }

    private func finish() {
        continuation?.resume(returning: ())
        continuation = nil
    }

}
