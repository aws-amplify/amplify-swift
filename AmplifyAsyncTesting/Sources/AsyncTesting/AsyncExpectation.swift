//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let nanoseconds = UInt64(seconds * Double(NSEC_PER_SEC))
        try await Task.sleep(nanoseconds: nanoseconds)
    }
}

public actor AsyncExpectation {
    enum State {
        case pending
        case fulfilled
        case timedOut
    }
    public typealias AsyncExpectationContinuation = CheckedContinuation<Void, Error>
    public let expectationDescription: String
    public var isInverted: Bool
    public var expectedFulfillmentCount: Int

    private var fulfillmentCount: Int = 0
    private var continuation: AsyncExpectationContinuation?
    private var state: State = .pending

    public var isFulfilled: Bool {
        state == .fulfilled
    }
    
    public func setShouldTrigger(_ shouldTrigger: Bool) {
        self.isInverted = !shouldTrigger
    }
    
    public func setExpectedFulfillmentCount(_ count: Int) {
        self.expectedFulfillmentCount = count
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
        try await withTaskCancellationHandler {
            try await handleWait()
        } onCancel: {
            Task {
                await cancel()
            }
        }
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
