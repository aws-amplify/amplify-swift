//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import SQLite

extension QueryOrderBy {
    var orderByClause: String {
        switch self {
        case .ascending(let key):
            return "\(key.stringValue) ASC"
        case .descending(let key):
            return "\(key.stringValue) DESC"
        }
    }
}
