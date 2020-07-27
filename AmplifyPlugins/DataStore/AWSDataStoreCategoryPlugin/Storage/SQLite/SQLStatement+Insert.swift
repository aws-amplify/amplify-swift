//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import SQLite

/// Represents a `insert` SQL statement associated with a `Model` instance.
struct InsertStatement: SQLStatement {

    let schema: ModelSchema
    let variables: [Binding?]

    init(model: Model) {
        self.schema = model.schema
        self.variables = model.sqlValues(for: schema.columns)
    }

    var stringValue: String {
        let fields = schema.columns
        let columns = fields.map { $0.columnName() }
        var statement = "insert into \(schema.name) "
        statement += "(\(columns.joined(separator: ", ")))\n"

        let variablePlaceholders = Array(repeating: "?", count: columns.count).joined(separator: ", ")
        statement += "values (\(variablePlaceholders))"

        return statement
    }
}
