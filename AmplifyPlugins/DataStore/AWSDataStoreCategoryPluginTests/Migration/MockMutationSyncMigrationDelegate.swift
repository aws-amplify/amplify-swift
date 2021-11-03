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
    var migrateError: DataStoreError?

    var migrationStepsCalled: [MigrationStep] = []

    enum MigrationStep {
        case precondition
        case transaction
        case needsMigration
        case cannotMigrate
        case clear
        case migrate
    }

    func preconditionCheck() throws {
        migrationStepsCalled.append(.precondition)
        if let preconditionCheckError = preconditionCheckError {
            throw preconditionCheckError
        }
    }

    func transaction(_ basicClosure: () throws -> Void) throws {
        migrationStepsCalled.append(.transaction)
        if let transactionError = transactionError {
            throw transactionError
        }

        try basicClosure()
    }

    func needsMigration() throws -> Bool {
        migrationStepsCalled.append(.needsMigration)
        if let needsMigrationError = needsMigrationError {
            throw needsMigrationError
        }
        return needsMigrationResult
    }

    func cannotMigrate() throws -> Bool {
        migrationStepsCalled.append(.cannotMigrate)
        if let cannotMigrateError = cannotMigrateError {
            throw cannotMigrateError
        }
        return cannotMigrateResult
    }

    func clear() throws {
        migrationStepsCalled.append(.clear)
        if let clearError = clearError {
            throw clearError
        }
    }

    func migrate() throws {
        migrationStepsCalled.append(.migrate)
        if let migrateError = migrateError {
            throw migrateError
        }
    }
}
