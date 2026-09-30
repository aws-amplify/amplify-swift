//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Carries a value that the compiler cannot prove is `Sendable` across an isolation
/// boundary.
///
/// This exists for interoperating with APIs that predate strict concurrency checking and
/// are safe in practice but not expressible as `Sendable` — most notably Combine's
/// `Future.Promise`, which is documented to be called at most once but is not declared
/// `Sendable`.
///
/// - Warning: This suppresses a real compiler guarantee. Only use it where the safety of
///   the access is established by the surrounding API contract, and say why at the use
///   site. Prefer making the underlying type `Sendable` whenever that is possible.
/// - Note: `public` because the plugin modules that build on `Amplify` — `AWSPluginsCore` and
///   the category plugins — hit the same Combine and `URLSession` interop cases. Keeping one
///   implementation here is preferable to a copy per module.
public struct UncheckedSendable<Value>: @unchecked Sendable {
    public let value: Value

    public init(_ value: Value) {
        self.value = value
    }
}
