//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSPluginsCore

class MutationSyncMetadataMigration: ModelMigration {

    weak var delegate: MutationSyncMetadataMigrationDelegate?

    init(delegate: MutationSyncMetadataMigrationDelegate) {
        self.delegate = delegate
    }

    func apply() throws {
        guard let delegate = delegate else {
            log.debug("Missing MutationSyncMetadataMigrationDelegate delegate")
            throw DataStoreError.unknown("Missing MutationSyncMetadataMigrationDelegate delegate", "", nil)
        }
        try delegate.preconditionCheck()
        try delegate.transaction {
            guard try delegate.needsMigration() else {
                return
            }

            if try delegate.cannotMigrate() {
                try delegate.clear()
            } else {
                try delegate.migrate()
            }
        }
    }
}

extension MutationSyncMetadataMigration: DefaultLogger { }
