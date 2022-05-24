//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import SQLite

struct AlterTableStatement: SQLStatement {
    var fromModelSchema: ModelSchema
    var modelSchema: ModelSchema

    var stringValue: String {
        return "ALTER TABLE \"\(fromModelSchema.name)\" RENAME TO \"\(modelSchema.name)\""
    }

    init(from fromModelSchema: ModelSchema, toModelSchema: ModelSchema) {
        self.fromModelSchema = fromModelSchema
        self.modelSchema = toModelSchema
    }
}
