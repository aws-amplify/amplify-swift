//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AWSDataStoreCategoryPlugin

// swiftlint:disable:next type_name
class MockMutationSyncMetadataMigrationDelegate: MutationSyncMetadataMigrationDelegate {

    var preconditionCheckError: DataStoreError?
    var transactionError: DataStoreError?
    // swiftlint:disable:next identifier_name
    var mutationSyncMetadataStoreEmptyOrMigratedError: DataStoreError?
    // swiftlint:disable:next identifier_name
    var mutationSyncMetadataStoreEmptyOrMigratedResult: Bool = false
    var containsDuplicateIdsAcrossModelsError: DataStoreError?
    var containsDuplicateIdsAcrossModelsResult: Bool = false
    var emptyMutationSyncMetadataStoreError: DataStoreError?
    var emptyModelSyncMetadataStoreError: DataStoreError?
    var removeMutationSyncMetadataCopyStoreError: DataStoreError?
    var createMutationSyncMetadataCopyStoreError: DataStoreError?
    var backfillMutationSyncMetadataError: DataStoreError?
    var removeMutationSyncMetadataStoreError: DataStoreError?
    var renameMutationSyncMetadataCopyError: DataStoreError?

    var stepsCalled: [DelegateStep] = []

    enum DelegateStep {
        case precondition
        case transaction
        case mutationSyncMetadataStoreEmptyOrMigrated
        case containsDuplicateIdsAcrossModels
        case emptyMutationSyncMetadataStore
        case emptyModelSyncMetadataStore
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

    func applyMigrationStep(_ step: MutationSyncMetadataMigrationStep) throws {
        switch step {
        case .emptyMutationSyncMetadataStore:
            try emptyMutationSyncMetadataStore()
        case .emptyModelSyncMetadataStore:
            try emptyModelSyncMetadataStore()
        case .removeMutationSyncMetadataCopyStore:
            try removeMutationSyncMetadataCopyStore()
        case .createMutationSyncMetadataCopyStore:
            try createMutationSyncMetadataCopyStore()
        case .backfillMutationSyncMetadata:
            try backfillMutationSyncMetadata()
        case .removeMutationSyncMetadataStore:
            try removeMutationSyncMetadataStore()
        case .renameMutationSyncMetadataCopy:
            try renameMutationSyncMetadataCopy()
        }
    }

    func mutationSyncMetadataStoreEmptyOrMigrated() throws -> Bool {
        stepsCalled.append(.mutationSyncMetadataStoreEmptyOrMigrated)
        if let error = mutationSyncMetadataStoreEmptyOrMigratedError {
            throw error
        }
        return mutationSyncMetadataStoreEmptyOrMigratedResult
    }

    func containsDuplicateIdsAcrossModels() throws -> Bool {
        stepsCalled.append(.containsDuplicateIdsAcrossModels)
        if let error = containsDuplicateIdsAcrossModelsError {
            throw error
        }
        return containsDuplicateIdsAcrossModelsResult
    }

    private func emptyMutationSyncMetadataStore() throws {
        stepsCalled.append(.emptyMutationSyncMetadataStore)
        if let error = emptyMutationSyncMetadataStoreError {
            throw error
        }
    }

    private func emptyModelSyncMetadataStore() throws {
        stepsCalled.append(.emptyModelSyncMetadataStore)
        if let error = emptyModelSyncMetadataStoreError {
            throw error
        }
    }

    private func removeMutationSyncMetadataCopyStore() throws {
        stepsCalled.append(.removeMutationSyncMetadataCopyStore)
        if let error = removeMutationSyncMetadataCopyStoreError {
            throw error
        }
    }

    private func createMutationSyncMetadataCopyStore() throws {
        stepsCalled.append(.createMutationSyncMetadataCopyStore)
        if let error = createMutationSyncMetadataCopyStoreError {
            throw error
        }
    }

    private func backfillMutationSyncMetadata() throws {
        stepsCalled.append(.backfillMutationSyncMetadata)
        if let error = backfillMutationSyncMetadataError {
            throw error
        }
    }

    private func removeMutationSyncMetadataStore() throws {
        stepsCalled.append(.removeMutationSyncMetadataStore)
        if let error = removeMutationSyncMetadataCopyStoreError {
            throw error
        }
    }

    private func renameMutationSyncMetadataCopy() throws {
        stepsCalled.append(.renameMutationSyncMetadataCopy)
        if let error = renameMutationSyncMetadataCopyError {
            throw error
        }
    }
}
