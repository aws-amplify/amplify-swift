//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Adds conformance to the [Comparable](https://developer.apple.com/documentation/swift/comparable) protocol.
/// Implementations are required to implement the `==` and `<` operators. Swift
/// takes care of deriving the other operations from those two.
///
/// - Note: the implementation simply delegates to the underlying `Date`.
extension Time: Comparable {

    public static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.date == rhs.date
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        return lhs.date < rhs.date
    }

}
