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


extension XCTestCase {

    /// Creates a new async expectation with an associated description.
    ///
    /// Use this method to create ``AsyncExpectation`` instances that can be
    /// fulfilled when asynchronous tasks in your tests complete.
    ///
    /// To fulfill an expectation that was created with `asyncExpectation(description:)`,
    /// call the expectation's `fulfill()` method when the asynchronous task in your
    /// test has completed.
    ///
    /// - Parameters:
    ///   - description: A string to display in the test log for this expectation, to help diagnose failures.
    ///   - isInverted: Indicates that the expectation is not intended to happen.
    ///   - expectedFulfillmentCount: The number of times fulfill() must be called before the expectation is completely fulfilled. (default = 1)
    public func asyncExpectation(description: String,
                                 isInverted: Bool = false,
                                 expectedFulfillmentCount: Int = 1) -> AsyncExpectation {
        AsyncExpectation(description: description,
                         isInverted: isInverted,
                         expectedFulfillmentCount: expectedFulfillmentCount)
    }

    /// Waits for the test to fulfill a set of expectations within a specified time.
    /// - Parameters:
    ///   - expectations: An array of async expectations that must be fulfilled.
    ///   - timeout: The number of seconds within which all expectations must be fulfilled.
    @MainActor
    public func waitForExpectations(_ expectations: [AsyncExpectation],
                                    timeout: Double = 1.0,
                                    file: StaticString = #filePath,
                                    line: UInt = #line) async {
        await AsyncTesting.waitForExpectations(expectations,
                                               timeout: timeout,
                                               file: file,
                                               line: line)
    }

}

public enum AsyncTesting {

    public static func expectation(description: String,
                                   isInverted: Bool = false,
                                   expectedFulfillmentCount: Int = 1) -> AsyncExpectation {
        AsyncExpectation(description: description,
                         isInverted: isInverted,
                         expectedFulfillmentCount: expectedFulfillmentCount)
    }

    @MainActor
    public static func waitForExpectations(_ expectations: [AsyncExpectation],
                                           timeout: Double = 1.0,
                                           file: StaticString = #filePath,
                                           line: UInt = #line) async {
        guard !expectations.isEmpty else { return }

        // check if all expectations are already satisfied and skip sleeping
        var count = 0
        for exp in expectations {
            if await exp.isFulfilled {
                count += 1
            }
        }
        if count == expectations.count {
            return
        }

        let timeout = Task {
            try await Task.sleep(seconds: timeout)
            for exp in expectations {
                await exp.timeOut(file: file, line: line)
            }
        }

        await waitUsingTaskGroup(expectations)

        timeout.cancel()
    }

    private static func waitUsingTaskGroup(_ expectations: [AsyncExpectation]) async {
        await withTaskGroup(of: Void.self) { group in
            for exp in expectations {
                group.addTask {
                    try? await exp.wait()
                }
            }
        }
    }

}
