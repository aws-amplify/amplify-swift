//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Delegate used by `MutationSyncMetadataMigration` which can be implemented by different
/// storage adapters.
protocol MutationSyncMetadataMigrationDelegate: AnyObject {

    func preconditionCheck() throws

    func transaction(_ basicClosure: BasicThrowableClosure) throws

    func needsMigration() throws -> Bool

    func cannotMigrate() throws -> Bool

    func clear() throws

    func migrate() throws
}
