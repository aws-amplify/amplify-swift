////
//// Copyright Amazon.com Inc. or its affiliates.
//// All Rights Reserved.
////
//// SPDX-License-Identifier: Apache-2.0
////
//
//import AmplifyAsyncTesting
//import XCTest
//
//extension XCTestCase {
//
//    /// Waits for the execution of a given async code, using a given async expectation,
//    /// and returns its result  or `nil` if it threw an error.
//    ///
//    /// This method will automatically call the expectation's `fulfill()` method when the async
//    /// code finishes, either successfully or with error.
//    ///
//    /// - Parameters:
//    ///   - expectation: The async expectation that will be fulfilled once the code in `action` completes.
//    ///   - timeout: How long to wait for `action` to complete. Defaults to `TestCommonConstants.networkTimeout`.
//    ///   - action: Closure containing async code.
//    ///   
//    /// - Returns:The result of successfuly running `action`, or `nil` if it threw an error.
//    @discardableResult
//    func wait<T>(with expectation: AsyncExpectation,
//                 timeout: TimeInterval = TestCommonConstants.networkTimeout,
//                 action: @escaping () async throws -> T) async -> T? {
//        let task = Task { () -> T? in
//            defer {
//                Task {
//                    await expectation.fulfill()
//                }
//            }
//            do {
//                return try await action()
//            } catch {
//                if !(error is CancellationError) {
//                    XCTFail("Failed with \(error)")
//                }
//                return nil
//            }
//        }
//        await waitForExpectations([expectation], timeout: timeout)
//        task.cancel()
//        return await task.value
//    }
//
//    /// Waits for the execution of a given async code and returns its result or `nil` if it threw an error.
//    ///
//    /// - Parameters:
//    ///   - name: The name that will be used to create the async expectation that will be fulfilled once the code in `action` completes.
//    ///   - timeout: How long to wait for `action` to complete. Defaults to `TestCommonConstants.networkTimeout`.
//    ///   - action: Closure containing async code.
//    ///
//    /// - Returns:The result of successfuly running `action`, or `nil` if it threw an error.
//    @discardableResult
//    func wait<T>(name: String,
//                 timeout: TimeInterval = TestCommonConstants.networkTimeout,
//                 action: @escaping () async throws -> T) async -> T? {
//        let expectation = asyncExpectation(description: name)
//        return await wait(with: expectation, timeout: timeout, action: action)
//    }
//
//    /// Waits for an error during the execution of a given async code, using a given async expectation,
//    /// and returns said error or `nil` if it run successfully.
//    ///
//    /// This method will automatically call the expectation's `fulfill()` method when the async
//    /// code finishes, either successfully or with error.
//    ///
//    /// - Parameters:
//    ///   - expectation: The async expectation that will be fulfilled once the code in `action` completes.
//    ///   - timeout: How long to wait for `action` to complete. Defaults to `TestCommonConstants.networkTimeout`.
//    ///   - action: Closure containing async code.
//    ///
//    /// - Returns:The error thrown during the execution of `action`, or `nil` if it run successfully.
//    @discardableResult
//    func waitError<T>(with expectation: AsyncExpectation,
//                      timeout: TimeInterval = TestCommonConstants.networkTimeout,
//                      action: @escaping () async throws -> T) async -> Error? {
//        let task = Task { () -> Error? in
//            defer {
//                Task { await expectation.fulfill() }
//            }
//            do {
//                let result = try await action()
//                XCTFail("Should not have completed, got \(result)")
//                return nil
//            } catch {
//                if error is CancellationError {
//                    return nil
//                }
//                return error
//            }
//        }
//        await waitForExpectations([expectation], timeout: timeout)
//        task.cancel()
//        return await task.value
//    }
//
//    /// Waits for an error during the execution of a given async code and returns said error
//    /// or `nil` if it run successfully.
//    ///
//    ///
//    /// - Parameters:
//    ///   - expectation: The async expectation that will be fulfilled once the code in `action` completes.
//    ///   - timeout: How long to wait for `action` to complete. Defaults to `TestCommonConstants.networkTimeout`.
//    ///   - action: Closure containing async code.
//    ///
//    /// - Returns:The error thrown during the execution of `action`, or `nil` if it run successfully.
//    @discardableResult
//    func waitError<T>(name: String,
//                      timeout: TimeInterval = TestCommonConstants.networkTimeout,
//                      action: @escaping () async throws -> T) async -> Error? {
//        let expectation = asyncExpectation(description: name)
//        return await waitError(with: expectation, timeout: timeout, action: action)
//    }
//}
