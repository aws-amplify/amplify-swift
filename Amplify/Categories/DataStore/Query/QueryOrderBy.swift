//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A simple struct that holds sort information that can be applied queries.

public enum QueryOrderBy {
    case ascending(CodingKey)
    case descending(CodingKey)
}

public struct SortInput {
    public let inputs: [QueryOrderBy]

    public init(_ inputs: QueryOrderBy...) {
        self.inputs = inputs
    }

    public static func ascending(_ field: CodingKey) -> SortInput {
        return SortInput(.ascending(field))
    }

    public static func descending(_ field: CodingKey) -> SortInput {
        return SortInput(.descending(field))
    }
}
