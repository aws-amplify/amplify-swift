//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin
@testable import AWSPluginsCore

class MutationSyncMetadataMigrationTests: MutationSyncMetadataMigrationTestBase {

    func testApply_MissingDelegate() {
        let delegate = MockMutationSyncMetadataMigrationDelegate()
        let migration = MutationSyncMetadataMigration(delegate: delegate)
        migration.delegate = nil

        do {
            try migration.apply()
        } catch {
            XCTAssertEqual(delegate.migrationStepsCalled, [])
            return
        }
        XCTFail("Should catch error")
    }

    func testApply_PreconditionFailure() {
        let delegate = MockMutationSyncMetadataMigrationDelegate()
        delegate.preconditionCheckError = DataStoreError.internalOperation("Failure", "", nil)
        let migration = MutationSyncMetadataMigration(delegate: delegate)

        do {
            try migration.apply()
        } catch {
            XCTAssertEqual(delegate.migrationStepsCalled, [.precondition])
            return
        }
        XCTFail("Should catch error")
    }

    func testApply_TransactionFailure() {
        let delegate = MockMutationSyncMetadataMigrationDelegate()
        delegate.transactionError = DataStoreError.internalOperation("Failure", "", nil)
        let migration = MutationSyncMetadataMigration(delegate: delegate)

        do {
            try migration.apply()
        } catch {
            XCTAssertEqual(delegate.migrationStepsCalled, [.precondition, .transaction])
            return
        }
        XCTFail("Should catch error")
    }

    func testApply_NeedsMigrationFailure() {
        let delegate = MockMutationSyncMetadataMigrationDelegate()
        delegate.needsMigrationError = DataStoreError.internalOperation("Failure", "", nil)
        let migration = MutationSyncMetadataMigration(delegate: delegate)

        do {
            try migration.apply()
        } catch {
            XCTAssertEqual(delegate.migrationStepsCalled, [.precondition, .transaction, .needsMigration])
            return
        }
        XCTFail("Should catch error")
    }

    func testApply_CannotMigrateFailure() {
        let delegate = MockMutationSyncMetadataMigrationDelegate()
        delegate.cannotMigrateError = DataStoreError.internalOperation("Failure", "", nil)
        let migration = MutationSyncMetadataMigration(delegate: delegate)

        do {
            try migration.apply()
        } catch {
            XCTAssertEqual(delegate.migrationStepsCalled, [.precondition,
                                                     .transaction,
                                                     .needsMigration,
                                                     .cannotMigrate])

            return
        }
        XCTFail("Should catch error")
    }

    func testApply_ClearFailure() {
        let delegate = MockMutationSyncMetadataMigrationDelegate()
        delegate.cannotMigrateResult = true
        delegate.clearError = DataStoreError.internalOperation("Failure", "", nil)
        let migration = MutationSyncMetadataMigration(delegate: delegate)

        do {
            try migration.apply()
        } catch {
            XCTAssertEqual(delegate.migrationStepsCalled, [.precondition,
                                                     .transaction,
                                                     .needsMigration,
                                                     .cannotMigrate,
                                                     .clear])
            return
        }
        XCTFail("Should catch error")
    }

    func testApply_MigrateFailure() {
        let delegate = MockMutationSyncMetadataMigrationDelegate()
        delegate.needsMigrationResult = true
        delegate.cannotMigrateResult = false
        delegate.migrateError = DataStoreError.internalOperation("Failure", "", nil)
        let migration = MutationSyncMetadataMigration(delegate: delegate)

        do {
            try migration.apply()
        } catch {
            XCTAssertEqual(delegate.migrationStepsCalled, [.precondition,
                                                     .transaction,
                                                     .needsMigration,
                                                     .cannotMigrate,
                                                     .migrate])
            return
        }
        XCTFail("Should catch error")
    }

    func testApplyMigrate() throws {
        let delegate = MockMutationSyncMetadataMigrationDelegate()
        delegate.needsMigrationResult = true
        delegate.cannotMigrateResult = false
        let migration = MutationSyncMetadataMigration(delegate: delegate)
        try migration.apply()
        XCTAssertEqual(delegate.migrationStepsCalled, [.precondition,
                                                 .transaction,
                                                 .needsMigration,
                                                 .cannotMigrate,
                                                 .migrate])
    }

    func testApplyClear() throws {
        let delegate = MockMutationSyncMetadataMigrationDelegate()
        delegate.needsMigrationResult = true
        delegate.cannotMigrateResult = true
        let migration = MutationSyncMetadataMigration(delegate: delegate)
        try migration.apply()
        XCTAssertEqual(delegate.migrationStepsCalled, [.precondition,
                                                 .transaction,
                                                 .needsMigration,
                                                 .cannotMigrate,
                                                 .clear])
    }
}
