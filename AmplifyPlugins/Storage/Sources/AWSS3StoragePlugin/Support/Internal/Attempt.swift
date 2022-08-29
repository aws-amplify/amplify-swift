//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Attempt to run expression to return a value or fail.
/// - Parameters:
///   - expression: expression
///   - fail: error handler
/// - Returns: optional result
func attempt<T>(_ expression: @autoclosure () throws -> T,
                fail: @autoclosure () -> ((Swift.Error) -> Void) = { _ in }) -> T? {
    do {
        return try expression()
    } catch {
        fail()(error)
        return nil
    }
}

/// Attempt to run an expression or fail.
/// - Parameters:
///   - expression: expression
///   - fail: error handler
/// - Returns: success
@discardableResult
func attempt(_ expression: @autoclosure () throws -> Void,
             fail: @autoclosure () -> ((Swift.Error) -> Void) = { _ in }) -> Bool {
    do {
        try expression()
        return true
    } catch {
        fail()(error)
        return false
    }
}
