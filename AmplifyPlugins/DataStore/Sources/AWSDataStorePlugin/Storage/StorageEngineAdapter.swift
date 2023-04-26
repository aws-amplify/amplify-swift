//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSPluginsCore

protocol StorageEngineAdapter: AnyObject, ModelStorageBehavior, ModelStorageErrorBehavior, StorageEngineMigrationAdapter {

    static var maxNumberOfPredicates: Int { get }

    func query(
        modelSchema: ModelSchema,
        predicate: QueryPredicate?,
        eagerLoad: Bool
    ) -> Swift.Result<[Model], DataStoreError>


    // MARK: - Synchronous APIs

    func exists(
        _ modelSchema: ModelSchema,
        withIdentifier id: ModelIdentifierProtocol,
        predicate: QueryPredicate?
    ) -> Swift.Result<Bool, DataStoreError>

    func queryMutationSync(for models: [Model], modelName: String) throws -> [MutationSync<AnyModel>]

    func queryMutationSync(forAnyModel anyModel: AnyModel) throws -> MutationSync<AnyModel>?

    func queryMutationSyncMetadata(for modelId: String, modelName: String) throws -> MutationSyncMetadata?

    func queryMutationSyncMetadata(for modelIds: [String], modelName: String) throws -> [MutationSyncMetadata]

    func queryModelSyncMetadata(for modelSchema: ModelSchema) throws -> ModelSyncMetadata?

    func transaction(_ basicClosure: BasicThrowableClosure) throws

    func clear(completion: @escaping DataStoreCallback<Void>)
}

protocol StorageEngineMigrationAdapter {

    @discardableResult func removeStore(for modelSchema: ModelSchema) throws -> String

    @discardableResult func createStore(for modelSchema: ModelSchema) throws -> String

    @discardableResult func emptyStore(for modelSchema: ModelSchema) throws -> String

    @discardableResult func renameStore(from: ModelSchema, toModelSchema: ModelSchema) throws -> String
}
