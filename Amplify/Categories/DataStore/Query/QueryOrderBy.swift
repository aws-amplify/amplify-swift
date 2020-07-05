//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol QuerySort {}

/// A simple struct that holds sort information that can be applied queries.

public struct QueryOrderBy: QuerySort {
    public let field: CodingKey
    public let order: String
}

extension QueryOrderBy {
    public static func asc(_ field: CodingKey) -> QueryOrderBy {
        return QueryOrderBy(field: field, order: "ASC")
    }

    public static func desc(_ field: CodingKey) -> QueryOrderBy {
        return QueryOrderBy(field: field, order: "DESC")
    }
}

public struct SortInput: QuerySort {
    public let inputs: [QueryOrderBy]

    public init(_ inputs: QueryOrderBy...) {
        self.inputs = inputs
    }

    public static func asc(_ field: CodingKey) -> SortInput {
        return self.init(QueryOrderBy(field: field, order: "ASC"))
    }

    public static func desc(_ field: CodingKey) -> SortInput {
        return self.init(QueryOrderBy(field: field, order: "DESC"))
    }
}
