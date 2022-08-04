//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(Combine)
import Foundation
import Combine

extension AmplifyAuthTask {
    
    var resultPublisher: AnyPublisher<Success, Failure> {
        internalResultPublisher
    }
    
    /// A Publisher that emits the result of the operation, or the associated failure.
    /// Cancelled operations will emit a completion without a value as long as the
    /// cancellation was processed before the operation was resolved.
    var internalResultPublisher: AnyPublisher<Success, Failure> {
        // We set this value in the initializer, so it's safe to force-unwrap and
        // force-cast here
        // swiftlint:disable:next force_cast
        let future = resultFuture as! Future<Success, Failure>
        return future
            .catch(interceptCancellation)
            .eraseToAnyPublisher()
    }

    /// Publish the result of the operation
    ///
    /// - Parameter result: the result of the operation
    func publish(result: AuthTaskResult) {
        // We assign this in init, so we know it's safe to force-unwrap here
        // swiftlint:disable:next force_cast
        let promise = resultPromise as! Future<Success, Failure>.Promise
        promise(result)
    }

    /// Utility method to help Swift type-cast the handling logic for cancellation
    /// errors vs. re-thrown errors
    ///
    /// - Parameter error: The error being intercepted
    /// - Returns: A publisher that either completes successfully (if the underlying
    ///   error of `error` is a cancellation) or re-emits the existing error
    private func interceptCancellation(error: Failure) -> AnyPublisher<Success, Failure> {
        if error.isOperationCancelledError {
            return Empty<Success, Failure>(completeImmediately: true).eraseToAnyPublisher()
        } else {
            return Fail<Success, Failure>(error: error).eraseToAnyPublisher()
        }
    }

}
#endif
