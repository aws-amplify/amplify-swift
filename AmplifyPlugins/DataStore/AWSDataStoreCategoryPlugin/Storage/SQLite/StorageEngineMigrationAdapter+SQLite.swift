//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import SQLite

extension SQLiteStorageEngineAdapter {

    @discardableResult func createStore(for modelSchema: ModelSchema) throws -> String {
        let createTableStatement = CreateTableStatement(modelSchema: modelSchema).stringValue
        let createIndexStatement = modelSchema.createIndexStatements()
        try connection.execute(createTableStatement)
        try connection.execute(createIndexStatement)
        return createTableStatement
    }

    @discardableResult func removeStore(for modelSchema: ModelSchema) throws -> String {
        let dropStatement = DropTableStatement(modelSchema: modelSchema).stringValue
        try connection.execute(dropStatement)
        return dropStatement
    }

    @discardableResult func emptyStore(for modelSchema: ModelSchema) throws -> String {
        let deleteStatement = DeleteStatement(modelSchema: modelSchema).stringValue
        try connection.execute(deleteStatement)
        return deleteStatement
    }

    @discardableResult func renameStore(from: ModelSchema, toModelSchema: ModelSchema) throws -> String {
        let alterTableStatement = AlterTableStatement(from: from, toModelSchema: toModelSchema).stringValue
        try connection.execute(alterTableStatement)
        return alterTableStatement
    }
}
