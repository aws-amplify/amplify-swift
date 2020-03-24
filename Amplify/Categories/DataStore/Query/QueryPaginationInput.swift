//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A simple struct that holds pagination information that can be applied queries.
public struct QueryPaginationInput {

    /// The default page size
    public static var defaultLimit: UInt = 100

    public let page: UInt
    public let limit: UInt

}

extension QueryPaginationInput {

    public static func page(_ page: UInt,
                            limit: UInt = QueryPaginationInput.defaultLimit) -> QueryPaginationInput {
        return QueryPaginationInput(page: page, limit: limit)
    }

    /// Utility that created a `QueryPaginationInput` with `page` 0 and `limit` 1
    public static var firstResult: QueryPaginationInput {
        .page(0, limit: 1)
    }

    /// Utility that created a `QueryPaginationInput` with `page` 0 and the default `limit`
    public static var firstPage: QueryPaginationInput {
        .page(0)
    }

}
