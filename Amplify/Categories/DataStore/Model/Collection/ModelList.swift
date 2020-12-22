//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// `ModelList` defines conformance to `Collection` for a list of `Model` items.
public protocol ModelList: Collection,
                           Codable,
                           ExpressibleByArrayLiteral,
                           Paginatable,
                           ModelListMarker where Index == Int,
                                                 ArrayLiteralElement == Element {

    init(factory: () -> Self)
}

extension ModelList {
    /// Factory Initializer to instantiate a concrete instance of a type that conforms to `ModelList`.
    public init(factory: () -> Self) {
        self = factory()
    }
}

/// Empty protocol used as a marker to detect `ModelList` conformance.
public protocol ModelListMarker { }
