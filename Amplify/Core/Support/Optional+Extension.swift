//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
		

import Foundation

extension Optional {
    ///
    /// Performing side effect function when data is exist
    /// - parameters:
    ///     - f: a function may perform side effects on wrapped data
    /// - returns:
    /// The original Optional object without changed
    @discardableResult
    @_spi(OptionalExtension)
    public func peek(_ f: @escaping (Wrapped) -> Void) -> Optional<Wrapped> {
        if case .some(let wrapped) = self {
            f(wrapped)
        }
        return self
    }
}
