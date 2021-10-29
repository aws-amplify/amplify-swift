//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import SQLite

protocol ModelMigration {
    func apply() throws
}

class ModelMigrations {
    var modelMigrations: [ModelMigration]

    init(connection: Connection, modelSchemas: [ModelSchema]) {
        self.modelMigrations = [AddModelNameToMutationSyncMetadataMigration(connection: connection, modelSchemas: modelSchemas)]
    }

    func apply() throws {
        for modelMigrations in modelMigrations {
            try modelMigrations.apply()
        }
    }
}
