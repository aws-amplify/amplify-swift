//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
@testable import AmplifyTestCommon
@testable import AWSDataStoreCategoryPlugin

extension MockSQLiteStorageEngineAdapter {
    enum ResponderKeys {
        case queryModelTypePredicateAdditionalStatements
        case queryMutationSyncMetadata
        case saveModelCompletion
        case saveUntypedModel
    }
}

// swiftlint:disable type_name

/// Note: In the original method, `completion` is non-escaping, so rather than attempting to pass `completion`, this
/// responder must return a value that the mock method will pass to the callback.
typealias QueryModelTypePredicateAdditionalStatementsResponder<M: Model> =
    MockResponder<(M.Type, QueryPredicate?, String?), DataStoreResult<[M]>>

typealias QueryMutationSyncMetadataResponder = ThrowingMockResponder<String, MutationSyncMetadata?>

typealias SaveModelCompletionResponder<M: Model> = MockResponder<(M, DataStoreCallback<M>), Void>

typealias SaveUntypedModelResponder = MockResponder<(Model, DataStoreCallback<Model>), Void>
