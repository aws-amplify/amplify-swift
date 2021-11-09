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
            if try delegate.mutationSyncMetadataStoreEmptyOrMigrated() {
                return
            }

            if try delegate.containsDuplicateIdsAcrossModels() {
                log.debug("Duplicate IDs found across different model types.")
                log.debug("Clearing MutationSyncMetadata and ModelSyncMetadata to force full sync.")
                try delegate.applyMigration(.emptyMutationSyncMetadataStore)
                try delegate.applyMigration(.emptyModelSyncMetadataStore)
            } else {
                log.debug("No duplicate IDs found.")
                log.debug("Modifying and backfilling MutationSyncMetadata")
                try delegate.applyMigration(.removeMutationSyncMetadataCopyStore)
                try delegate.applyMigration(.createMutationSyncMetadataCopyStore)
                try delegate.applyMigration(.backfillMutationSyncMetadata)
                try delegate.applyMigration(.removeMutationSyncMetadataStore)
                try delegate.applyMigration(.renameMutationSyncMetadataCopy)
            }
        }
    }
}

extension MutationSyncMetadataMigration: DefaultLogger { }
