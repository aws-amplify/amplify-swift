//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// A `Builder` constructs instances of `Product`, either from scratch by using a
/// designated initializer (which should provide reasonable defaults where
/// possible), defaults or by copying values from a previous `Product` instance.
protocol Builder {
    associatedtype Product

    /// Constructs a new `Builder` that will produce a `Product` with values from `previousProduct`
    init(_ previousProduct: Product)

    /// Builds and returns a new instance of `Product`. Repeated invocations of `build()` will
    /// produce new instances of `Product` with the same underlying values. Likewise, changing any
    /// of the `Builder`'s values will cause the Builder to produce instances with those new values
    /// upon subsequent invocations of `build()`.
    func build() -> Product
}
