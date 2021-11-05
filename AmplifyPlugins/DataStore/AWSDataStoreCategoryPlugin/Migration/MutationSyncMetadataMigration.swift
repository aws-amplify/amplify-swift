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

    enum MutationSyncMetadataMigrationStep {
        case removeMutationSyncMetadataCopyStore
        case createMutationSyncMetadataCopyStore
        case backfillMutationSyncMetadata
        case removeMutationSyncMetadataStore
        case renameMutationSyncMetadataCopy
    }

    let migrationSteps: [MutationSyncMetadataMigrationStep] = [.removeMutationSyncMetadataCopyStore,
                                                               .createMutationSyncMetadataCopyStore,
                                                               .backfillMutationSyncMetadata,
                                                               .removeMutationSyncMetadataStore,
                                                               .renameMutationSyncMetadataCopy]

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
                log.debug("Modifying and backfilling MutationSyncMetadata")
                for step in migrationSteps {
                    try applyMigrationStep(step, delegate: delegate)
                }

            }
        }
    }

    func applyMigrationStep(_ step: MutationSyncMetadataMigrationStep,
                            delegate: MutationSyncMetadataMigrationDelegate) throws {
        switch step {
        case .removeMutationSyncMetadataCopyStore:
            try delegate.removeMutationSyncMetadataCopyStore()
        case .createMutationSyncMetadataCopyStore:
            try delegate.createMutationSyncMetadataCopyStore()
        case .backfillMutationSyncMetadata:
            try delegate.backfillMutationSyncMetadata()
        case .removeMutationSyncMetadataStore:
            try delegate.removeMutationSyncMetadataStore()
        case .renameMutationSyncMetadataCopy:
            try delegate.renameMutationSyncMetadataCopy()
        }
    }
}

extension MutationSyncMetadataMigration: DefaultLogger { }
