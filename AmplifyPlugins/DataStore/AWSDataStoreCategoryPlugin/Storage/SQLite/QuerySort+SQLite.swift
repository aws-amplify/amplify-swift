//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import SQLite

extension QuerySortBy {
    var fieldName: String {
        switch self {
        case .ascending(let key), .descending(let key):
            return key.stringValue
        }
    }

    var fieldOrder: String {
        switch self {
        case .ascending:
            return "asc"
        case .descending:
            return "desc"
        }
    }
}

extension QuerySortInput {
    func sortStatement(namespace: String) -> String {
        let sqlResult = inputs
            .map { QuerySortInput.columnFor(field: $0.fieldName,
                                            order: $0.fieldOrder,
                                            namespace: namespace) }

        return sqlResult.joined(separator: ", ")
    }

    static func columnFor(field: String,
                          order: String,
                          namespace: String) -> String {
        return namespace.quoted() + "." + field.quoted() + " " + order

    }
}
