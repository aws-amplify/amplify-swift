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
typealias QueryModelTypePredicateResponder<M: Model> =
    MockResponder<(M.Type, QueryPredicate?), DataStoreResult<[M]>>

typealias QueryMutationSyncMetadataResponder = ThrowingMockResponder<String, MutationSyncMetadata?>

typealias QueryMutationSyncMetadatasResponder = ThrowingMockResponder<[String], [MutationSyncMetadata]>

typealias SaveModelCompletionResponder<M: Model> = MockResponder<(M, DataStoreCallback<M>), Void>

typealias SaveUntypedModelResponder = MockResponder<(Model, DataStoreCallback<Model>), Void>

typealias DeleteUntypedModelCompletionResponder = MockResponder<(Model.Type, String), DataStoreResult<Void>>

extension MockStorageEngineBehavior {
    enum ResponderKeys {
        case startSync
        case stopSync
        case clear
        case query
    }
}

typealias StartSyncResponder = MockResponder<String, Void>
typealias StopSyncResponder = MockResponder<String, Void>
typealias ClearResponder = MockResponder<String, Void>
typealias QueryResponder<M: Model> = MockResponder<Void, DataStoreResult<[M]>>
