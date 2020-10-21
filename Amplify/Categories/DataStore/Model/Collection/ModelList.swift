//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Empty protocol used as a marker for plugins to detect `ModelList` conformance. `ModelList` cannot be used directly
/// since it has associated type requirements.
public protocol ModelListMarker { }

/// `ModelList` defines conformance to`Collection` and `Paginatable` with elements of type `Model`
public protocol ModelList: Collection,
                           Codable,
                           ExpressibleByArrayLiteral,
                           Paginatable,
                           ModelListMarker where Index == Int,
                                                 ArrayLiteralElement == Element, Element: Model {
    init(factory: () -> Self)
}

extension ModelList {
    /// Factory Initializer to instantiate a concrete instance of a type that conforms to`ModelList`.
    public init(factory: () -> Self) {
        self = factory()
    }
}
