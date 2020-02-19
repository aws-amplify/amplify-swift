//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Protocol for the connection to make it retryable.
public protocol RetryableConnection {

    /// Adds a RetryHandler for the connection. The retry handler checks the error
    /// and decides whether to retry or not.
    /// - Parameter handler
    func addRetryHandler(handler: ConnectionRetryHandler)

}

/// Protocol for connection retry handler.
public protocol ConnectionRetryHandler {

    /// Check if we should retry the request or not.
    /// - Parameter error: Connection provider error.
    func shouldRetryRequest(for error: ConnectionProviderError) -> RetryAdvice

}

public protocol RetryAdvice {
    var shouldRetry: Bool { get }
    var retryInterval: DispatchTimeInterval? { get }
}
