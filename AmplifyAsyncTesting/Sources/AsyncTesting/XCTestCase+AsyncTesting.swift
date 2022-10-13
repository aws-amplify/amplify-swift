//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest

extension XCTestCase {
    public static let defaultTimeoutForAsyncExpectations = TimeInterval(60)
    public static let defaultNetworkTimeoutForAsyncExpectations = TimeInterval(10)

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

    /// Run a task with a timeout using an `AsyncExpectation`.
    /// - Parameters:
    ///   - timeout: timeout
    ///   - operation: operation to run
    /// - Returns: result of closure
    @discardableResult
    public func testTask<Success>(timeout: Double = defaultTimeoutForAsyncExpectations,
                                  file: StaticString = #filePath,
                                  line: UInt = #line,
                                  @_implicitSelfCapture operation: @escaping @Sendable () async throws -> Success) async throws -> Success {
        let done = asyncExpectation(description: "done")

        let task = Task {
            let result = try await operation()
            await done.fulfill()
            return result
        }

        await waitForExpectations([done], timeout: timeout, file: file, line: line)

        return try await task.value
    }

    /// Waits for the execution of a given async code, using a given async expectation,
    /// and returns its result  or `nil` if it threw an error.
    ///
    /// This method will automatically call the expectation's `fulfill()` method when the async
    /// code finishes, either successfully or with error.
    ///
    /// - Parameters:
    ///   - expectation: The async expectation that will be fulfilled once the code in `action` completes.
    ///   - timeout: How long to wait for `action` to complete. Defaults to 10 seconds.
    ///   - action: Closure containing async code.
    ///
    /// - Returns:The result of successfuly running `action`, or `nil` if it threw an error.
    @discardableResult
    func wait<T>(with expectation: AsyncExpectation,
                 timeout: TimeInterval = defaultNetworkTimeoutForAsyncExpectations,
                 action: @escaping () async throws -> T) async -> T? {
        let task = Task { () -> T? in
            defer {
                Task {
                    await expectation.fulfill()
                }
            }
            do {
                return try await action()
            } catch {
                if !(error is CancellationError) {
                    XCTFail("Failed with \(error)")
                }
                return nil
            }
        }
        await waitForExpectations([expectation], timeout: timeout)
        task.cancel()
        return await task.value
    }

    /// Waits for the execution of a given async code and returns its result or `nil` if it threw an error.
    ///
    /// - Parameters:
    ///   - name: The name that will be used to create the async expectation that will be fulfilled once the code in `action` completes.
    ///   - timeout: How long to wait for `action` to complete. Defaults to 10 seconds.
    ///   - action: Closure containing async code.
    ///
    /// - Returns:The result of successfuly running `action`, or `nil` if it threw an error.
    @discardableResult
    func wait<T>(name: String,
                 timeout: TimeInterval = defaultNetworkTimeoutForAsyncExpectations,
                 action: @escaping () async throws -> T) async -> T? {
        let expectation = asyncExpectation(description: name)
        return await wait(with: expectation, timeout: timeout, action: action)
    }

    /// Waits for an error during the execution of a given async code, using a given async expectation,
    /// and returns said error or `nil` if it run successfully.
    ///
    /// This method will automatically call the expectation's `fulfill()` method when the async
    /// code finishes, either successfully or with error.
    ///
    /// - Parameters:
    ///   - expectation: The async expectation that will be fulfilled once the code in `action` completes.
    ///   - timeout: How long to wait for `action` to complete. Defaults to 10 seconds.
    ///   - action: Closure containing async code.
    ///
    /// - Returns:The error thrown during the execution of `action`, or `nil` if it run successfully.
    @discardableResult
    func waitError<T>(with expectation: AsyncExpectation,
                      timeout: TimeInterval = defaultNetworkTimeoutForAsyncExpectations,
                      action: @escaping () async throws -> T) async -> Error? {
        let task = Task { () -> Error? in
            defer {
                Task { await expectation.fulfill() }
            }
            do {
                let result = try await action()
                XCTFail("Should not have completed, got \(result)")
                return nil
            } catch {
                if error is CancellationError {
                    return nil
                }
                return error
            }
        }
        await waitForExpectations([expectation], timeout: timeout)
        task.cancel()
        return await task.value
    }

    /// Waits for an error during the execution of a given async code and returns said error
    /// or `nil` if it run successfully.
    ///
    ///
    /// - Parameters:
    ///   - expectation: The async expectation that will be fulfilled once the code in `action` completes.
    ///   - timeout: How long to wait for `action` to complete. Defaults to 10 seconds.
    ///   - action: Closure containing async code.
    ///
    /// - Returns:The error thrown during the execution of `action`, or `nil` if it run successfully.
    @discardableResult
    func waitError<T>(name: String,
                      timeout: TimeInterval = defaultNetworkTimeoutForAsyncExpectations,
                      action: @escaping () async throws -> T) async -> Error? {
        let expectation = asyncExpectation(description: name)
        return await waitError(with: expectation, timeout: timeout, action: action)
    }

}
