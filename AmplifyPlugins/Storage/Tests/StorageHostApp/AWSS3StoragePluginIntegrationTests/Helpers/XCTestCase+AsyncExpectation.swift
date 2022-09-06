//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AmplifyAsyncTesting
import XCTest

extension XCTestCase {
    @discardableResult
    func wait<T>(with expectation: AsyncExpectation,
                 timeout: TimeInterval = TestCommonConstants.networkTimeout,
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

    @discardableResult
    func wait<T>(name: String,
                 timeout: TimeInterval = TestCommonConstants.networkTimeout,
                 action: @escaping () async throws -> T) async -> T? {
        let expectation = asyncExpectation(description: name)
        return await wait(with: expectation, timeout: timeout, action: action)
    }

    @discardableResult
    func waitError<T>(with expectation: AsyncExpectation,
                      timeout: TimeInterval = TestCommonConstants.networkTimeout,
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

    @discardableResult
    func waitError<T>(name: String,
                      timeout: TimeInterval = TestCommonConstants.networkTimeout,
                      action: @escaping () async throws -> T) async -> Error? {
        let expectation = asyncExpectation(description: name)
        return await waitError(with: expectation, timeout: timeout, action: action)
    }
}
