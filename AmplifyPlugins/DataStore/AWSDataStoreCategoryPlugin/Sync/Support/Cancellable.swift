//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

//Note: There is already a Cancellable in Core/Support/Cancellable.swift, which does not seem to be
//       visible to this package.  In any case, the protocol is the exact same.

/// The conforming type supports canceling an in-process operation. The exact semantics of "canceling" are not defined
/// in the protocol. Specifically, there is no guarantee that a `cancel` results in immediate cessation of activity.
public protocol Cancellable {
    func cancel()
}
