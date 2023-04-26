//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

extension MockSQLiteStorageEngineAdapter {
    enum ResponderKeys {
        // swiftlint:disable:next identifier_name
        case queryModelTypePredicate
        case queryMutationSyncMetadata
        case queryMutationSyncMetadatas
        case saveModelCompletion
        case saveUntypedModel
        case deleteUntypedModel
    }
}

// swiftlint:disable type_name

/// Note: In the original method, `completion` is non-escaping, so rather than attempting to pass `completion`, this
/// responder must return a value that the mock method will pass to the callback.
typealias QueryModelTypePredicateResponder<M: Model> = (M.Type, QueryPredicate?) -> DataStoreResult<[M]>

typealias QueryMutationSyncMetadataResponder = (String) throws -> MutationSyncMetadata?

typealias QueryMutationSyncMetadatasResponder = ([String]) throws -> [MutationSyncMetadata]

typealias SaveModelCompletionResponder<M: Model> = (M) -> DataStoreResult<M>

typealias SaveUntypedModelResponder = (Model) -> DataStoreResult<Model>

typealias DeleteUntypedModelCompletionResponder = (String) -> DataStoreResult<Void>

extension MockStorageEngineBehavior {
    enum ResponderKeys {
        case startSync
        case stopSync
        case clear
        case query
    }
}

typealias StartSyncResponder = (String) -> Void
typealias StopSyncResponder = (String) -> Void
typealias ClearResponder = (String) -> Void
typealias QueryResponder<M: Model> = () -> DataStoreResult<[M]>
