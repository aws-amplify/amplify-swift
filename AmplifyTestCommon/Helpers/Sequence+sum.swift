//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public extension Sequence where Element: SignedInteger {
    @inlinable func sum() -> Element {
        reduce(0, +)
    }
}

public extension Sequence where Element: UnsignedInteger {
    @inlinable func sum() -> Element {
        reduce(0, +)
    }
}

