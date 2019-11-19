//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import SQLite

/// Represents a `update` SQL statement.
struct UpdateStatement: SQLStatement {

    let modelType: Model.Type
    private let model: Model

    init(model: Model) {
        self.modelType = type(of: model)
        self.model = model
    }

    var stringValue: String {
        let schema = modelType.schema
        let columns = updateColumns.map { $0.columnName() }

        var statement = "update \(schema.name) set"
        columns.forEach { column in
            statement += "\n  \(column) = ?"
        }
        // TODO allow predicates for update?
        statement += "\nwhere \(schema.primaryKey.columnName()) = ?"

        return statement
    }

    var variables: [Binding?] {
        var bindings = model.sqlValues(for: updateColumns)
        bindings.append(model.id)
        return bindings
    }

    private var updateColumns: [ModelField] {
        modelType.schema.columns.filter { !$0.isPrimaryKey }
    }
}
