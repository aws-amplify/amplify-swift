//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A simple struct that holds sort information that can be applied queries.

public enum QuerySortBy {
    case ascending(CodingKey)
    case descending(CodingKey)
}

public struct QuerySortInput {
    public let inputs: [QuerySortBy]

    public init(_ inputs: [QuerySortBy]) {
        self.inputs = inputs
    }

    public static func by(_ inputs: QuerySortBy...) -> QuerySortInput {
        return self.init(inputs)
    }

    public static func ascending(_ field: CodingKey) -> QuerySortInput {
        return QuerySortInput([.ascending(field)])
    }

    public static func descending(_ field: CodingKey) -> QuerySortInput {
        return QuerySortInput([.descending(field)])
    }
}
