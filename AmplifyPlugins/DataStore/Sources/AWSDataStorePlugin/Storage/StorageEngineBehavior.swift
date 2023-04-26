//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import Combine

enum StorageEngineEvent {
    case started
    case mutationEvent(MutationEvent)
    case modelSyncedEvent(ModelSyncedEvent)
    case syncQueriesReadyEvent
    case readyEvent
}

protocol StorageEngineBehavior: AnyObject {

    var publisher: AnyPublisher<StorageEngineEvent, DataStoreError> { get }

    /// start remote sync, based on if sync is enabled and/or authentication is required
    func startSync(completion: @escaping DataStoreCallback<Void>)
    func stopSync(completion: @escaping DataStoreCallback<Void>)
    func clear(completion: @escaping DataStoreCallback<Void>)

    func setUp(modelSchemas: [ModelSchema]) throws

    func applyModelMigrations(modelSchemas: [ModelSchema]) throws

    func query<M: Model>(
        _ modelType: M.Type,
        modelSchema: ModelSchema,
        withIdentifier identifier: ModelIdentifierProtocol,
        condition: QueryPredicate?,
        eagerLoad: Bool
    ) -> Swift.Result<M?, DataStoreError>

    func query<M: Model>(
        _ modelType: M.Type,
        modelSchema: ModelSchema,
        condition: QueryPredicate?,
        sort: [QuerySortDescriptor]?,
        paginationInput: QueryPaginationInput?,
        eagerLoad: Bool
    ) -> Swift.Result<[M], DataStoreError>

    func save<M: Model>(
        _ model: M,
        modelSchema: ModelSchema,
        condition: QueryPredicate?,
        eagerLoad: Bool
    ) async -> Swift.Result<(M, MutationEvent.MutationType), DataStoreError>

    func delete<M: Model>(
        _ modelType: M.Type,
        modelSchema: ModelSchema,
        withIdentifier identifier: ModelIdentifierProtocol,
        condition: QueryPredicate?
    ) async -> Swift.Result<M?, DataStoreError>

    // bulk deletion
    func delete<M: Model>(
        _ modelType: M.Type,
        modelSchema: ModelSchema,
        condition: QueryPredicate
    ) async -> Swift.Result<[M], DataStoreError>
}
