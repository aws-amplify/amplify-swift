//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Represents a `create table` SQL statement. The table is created based on the `ModelSchema`
/// associated with the passed `Model.Type`.
struct CreateTableStatement: SQLStatement {

    let modelType: Model.Type

    init(modelType: Model.Type) {
        self.modelType = modelType
    }

    var stringValue: String {
        let schema = modelType.schema
        let name = schema.name
        var statement = "create table if not exists \(name) (\n"

        let columns = schema.columns
        let foreignKeys = schema.foreignKeys

        for (index, column) in columns.enumerated() {
            statement += "  \"\(column.sqlName)\" \(column.sqlType.rawValue)"
            if column.isPrimaryKey {
                statement += " primary key"
            }
            if column.isRequired {
                statement += " not null"
            }

            let isNotLastColumn = index < columns.endIndex - 1
            if isNotLastColumn {
                statement += ",\n"
            }
        }

        let hasForeignKeys = !foreignKeys.isEmpty
        if hasForeignKeys {
            statement += ",\n"
        }

        for foreignKey in foreignKeys {
            statement += "  foreign key(\"\(foreignKey.sqlName)\") "
            let connectedModel = foreignKey.requiredConnectedModel
            let connectedId = connectedModel.schema.primaryKey
            let connectedModelName = connectedModel.schema.name
            statement += "references \(connectedModelName)(\"\(connectedId.sqlName)\")\n"
            statement += "    on delete cascade"
        }

        statement += "\n);"
        return statement
    }
}
