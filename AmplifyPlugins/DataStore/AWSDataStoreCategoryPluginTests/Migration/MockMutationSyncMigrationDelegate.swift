//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSDataStoreCategoryPlugin

class MockMutationSyncMetadataMigrationDelegate: MutationSyncMetadataMigrationDelegate {
    var preconditionCheckError: DataStoreError?
    var transactionError: DataStoreError?
    var needsMigrationError: DataStoreError?
    var needsMigrationResult: Bool = true
    var cannotMigrateError: DataStoreError?
    var cannotMigrateResult: Bool = false
    var clearError: DataStoreError?
    var removeMutationSyncMetadataCopyStoreError: DataStoreError?
    var createMutationSyncMetadataCopyStoreError: DataStoreError?
    var backfillMutationSyncMetadataError: DataStoreError?
    var removeMutationSyncMetadataStoreError: DataStoreError?
    var renameMutationSyncMetadataCopyError: DataStoreError?

    var stepsCalled: [DelegateStep] = []

    enum DelegateStep {
        case precondition
        case transaction
        case needsMigration
        case cannotMigrate
        case clear
        case removeMutationSyncMetadataCopyStore
        case createMutationSyncMetadataCopyStore
        case backfillMutationSyncMetadata
        case removeMutationSyncMetadataStore
        case renameMutationSyncMetadataCopy
    }

    func preconditionCheck() throws {
        stepsCalled.append(.precondition)
        if let preconditionCheckError = preconditionCheckError {
            throw preconditionCheckError
        }
    }

    func transaction(_ basicClosure: () throws -> Void) throws {
        stepsCalled.append(.transaction)
        if let transactionError = transactionError {
            throw transactionError
        }

        try basicClosure()
    }

    func needsMigration() throws -> Bool {
        stepsCalled.append(.needsMigration)
        if let needsMigrationError = needsMigrationError {
            throw needsMigrationError
        }
        return needsMigrationResult
    }

    func cannotMigrate() throws -> Bool {
        stepsCalled.append(.cannotMigrate)
        if let cannotMigrateError = cannotMigrateError {
            throw cannotMigrateError
        }
        return cannotMigrateResult
    }

    func clear() throws {
        stepsCalled.append(.clear)
        if let clearError = clearError {
            throw clearError
        }
    }

    func removeMutationSyncMetadataCopyStore() throws -> String {
        stepsCalled.append(.removeMutationSyncMetadataCopyStore)
        if let error = removeMutationSyncMetadataCopyStoreError {
            throw error
        }
        return ""
    }

    func createMutationSyncMetadataCopyStore() throws -> String {
        stepsCalled.append(.createMutationSyncMetadataCopyStore)
        if let error = createMutationSyncMetadataCopyStoreError {
            throw error
        }
        return ""
    }

    func backfillMutationSyncMetadata() throws -> String {
        stepsCalled.append(.backfillMutationSyncMetadata)
        if let error = backfillMutationSyncMetadataError {
            throw error
        }
        return ""
    }

    func removeMutationSyncMetadataStore() throws -> String {
        stepsCalled.append(.removeMutationSyncMetadataStore)
        if let error = removeMutationSyncMetadataCopyStoreError {
            throw error
        }
        return ""
    }

    func renameMutationSyncMetadataCopy() throws -> String {
        stepsCalled.append(.renameMutationSyncMetadataCopy)
        if let error = renameMutationSyncMetadataCopyError {
            throw error
        }
        return ""
    }
}
