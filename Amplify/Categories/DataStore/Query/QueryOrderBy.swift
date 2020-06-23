//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
/// A simple struct that holds pagination information that can be applied queries.
public struct QueryOrderBy {
    public let field: CodingKey
    public let DESC: Bool
}

extension QueryOrderBy {
    public static func ordering(field: CodingKey,
                                DESC: Bool = false) -> QueryOrderBy {
        return QueryOrderBy(field: field, DESC: DESC)
    }
}
