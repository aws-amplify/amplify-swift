//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSPluginsCore
import Combine

@testable import Amplify
@testable import AWSDataStorePlugin

class MockSQLiteStorageEngineAdapter: StorageEngineAdapter {

    static var maxNumberOfPredicates: Int = 950

    var responders = [ResponderKeys: Any]()

    var resultForQuery: DataStoreResult<[Model]>?
    var resultForSave: DataStoreResult<Model>?

    var resultForQueryMutationSyncMetadata: MutationSyncMetadata?
    var resultForQueryMutationSyncMetadatas: [MutationSyncMetadata]
    var errorToThrowOnMutationSyncMetadata: DataStoreError?
    var errorToThrowOnTransaction: Error?

    var shouldReturnErrorOnSaveMetadata: Bool
    var shouldReturnErrorOnDeleteMutation: Bool
    var shouldIgnoreError: Bool

    var resultForQueryModelSyncMetadata: ModelSyncMetadata?
    var listenerForModelSyncMetadata: BasicClosure?

    init() {
        self.shouldReturnErrorOnSaveMetadata = false
        self.shouldReturnErrorOnDeleteMutation = false
        self.shouldIgnoreError = false
        self.resultForQueryMutationSyncMetadatas = [MutationSyncMetadata]()
    }

    func setUp(modelSchemas: [ModelSchema]) throws {
        XCTFail("Not expected to execute")
    }

    func applyModelMigrations(modelSchemas: [ModelSchema]) throws {
        XCTFail("Not expected to execute")
    }

    // MARK: - Responses

    func returnOnQuery(dataStoreResult: DataStoreResult<[Model]>?) {
        resultForQuery = dataStoreResult
    }

    func returnOnQueryMutationSyncMetadata(_ mutationSyncMetadata: MutationSyncMetadata?) {
        resultForQueryMutationSyncMetadata = mutationSyncMetadata
    }

    func returnOnQueryMutationSyncMetadatas(_ mutationSyncMetadatas: [MutationSyncMetadata]) {
        resultForQueryMutationSyncMetadatas = mutationSyncMetadatas
    }

    func returnOnSave(dataStoreResult: DataStoreResult<Model>?) {
        resultForSave = dataStoreResult
    }

    func returnOnQueryModelSyncMetadata(_ metadata: ModelSyncMetadata?, listener: BasicClosure? = nil) {
        resultForQueryModelSyncMetadata = metadata
        listenerForModelSyncMetadata = listener
    }

    func throwOnQueryMutationSyncMetadata(error: DataStoreError) {
        errorToThrowOnMutationSyncMetadata = error
    }

    func throwOnTransaction(error: DataStoreError) {
        errorToThrowOnTransaction = error
    }

    // MARK: - StorageEngineAdapter

    func create<M: Model>(
        _ model: M,
        modelSchema: ModelSchema,
        condition: QueryPredicate?,
        eagerLoad: Bool
    ) -> Result<M, DataStoreError> {
        .failure(DataStoreError(error: "Not expected to execute"))
    }

    func update<M: Model>(
        _ model: M,
        modelSchema: ModelSchema,
        condition: QueryPredicate?,
        eagerLoad: Bool
    ) -> Result<M, DataStoreError> {
        .failure(DataStoreError(error: "Not expected to execute"))
    }

    func delete(
        modelSchema: ModelSchema,
        withIdentifier identifier: ModelIdentifierProtocol,
        condition: QueryPredicate?
    ) -> Swift.Result<Void, DataStoreError> {
        if let responder = responders[.deleteUntypedModel] as? DeleteUntypedModelCompletionResponder {
            return responder(identifier.stringValue)
        }
        return shouldReturnErrorOnDeleteMutation
        ? .failure(causedBy: DataStoreError.invalidModelName("DelMutate"))
        : .emptyResult
    }

    func delete(
        modelSchema: ModelSchema,
        condition: QueryPredicate
    ) -> Result<Void, DataStoreError> {
        return shouldReturnErrorOnDeleteMutation
        ? .failure(causedBy: DataStoreError.invalidModelName("DelMutate"))
        : .emptyResult
    }

    func delete(untypedModelType modelType: Model.Type,
                modelSchema: ModelSchema,
                withIdentifier identifier: ModelIdentifierProtocol,
                condition: QueryPredicate?
    ) -> DataStoreResult<Void> {
        if let responder = responders[.deleteUntypedModel] as? DeleteUntypedModelCompletionResponder {
            return responder(identifier.stringValue)
        }
        
        return shouldReturnErrorOnDeleteMutation
        ? .failure(causedBy: DataStoreError.invalidModelName("DelMutate"))
        : .emptyResult
    }

    func query(
        modelSchema: ModelSchema,
        predicate: QueryPredicate?,
        eagerLoad: Bool
    ) -> Result<[Model], DataStoreError> {
        resultForQuery ?? .failure(DataStoreError.invalidOperation(causedBy: nil))
    }

    func query<M: Model>(_ modelType: M.Type,
                         predicate: QueryPredicate?,
                         paginationInput: QueryPaginationInput?,
                         eagerLoad: Bool,
                         completion: DataStoreCallback<[M]>) {
        XCTFail("Not expected to execute")
    }

    func query<M: Model>(_ modelType: M.Type,
                         modelSchema: ModelSchema,
                         predicate: QueryPredicate?,
                         sort: [QuerySortDescriptor]?,
                         paginationInput: QueryPaginationInput?,
                         eagerLoad: Bool,
                         completion: (DataStoreResult<[M]>) -> Void) {
        XCTFail("Not expected to execute")
    }

    func queryMutationSync(for models: [Model], modelName: String) throws -> [MutationSync<AnyModel>] {
        XCTFail("Not expected to execute")
        return []
    }

    func exists(
        _ modelSchema: ModelSchema,
        withIdentifier id: ModelIdentifierProtocol,
        predicate: QueryPredicate?
    ) -> Result<Bool, DataStoreError> {
        .failure(DataStoreError(error: "Not expected to execute"))
    }


    func save(_ model: Model, eagerLoad: Bool) -> Result<Model, DataStoreError> {
        if let responder = responders[.saveUntypedModel] as? SaveUntypedModelResponder {
            return responder(model)
        }

        return resultForSave!
    }

    func save<M: Model>(
        _ model: M,
        condition: QueryPredicate?,
        eagerLoad: Bool
    ) -> DataStoreResult<M> {
        if let responder = responders[.saveModelCompletion] as? SaveModelCompletionResponder<M> {
            return responder(model)
        }

        return shouldReturnErrorOnSaveMetadata
            ? .failure(DataStoreError.invalidModelName("forceError"))
            : .success(model)
    }

    func save<M: Model>(
        _ model: M,
        modelSchema: ModelSchema,
        condition: QueryPredicate?,
        eagerLoad: Bool
    ) -> Result<(M, MutationEvent.MutationType), DataStoreError> {
        if let responder = responders[.saveModelCompletion] as? SaveModelCompletionResponder<M> {
            return responder(model).map { ($0, .create) }
        }

        return shouldReturnErrorOnSaveMetadata
            ? .failure(DataStoreError.invalidModelName("forceError"))
            : .success((model, .create))
    }

    func queryMutationSync(forAnyModel anyModel: AnyModel) throws -> MutationSync<AnyModel>? {
        XCTFail("Not expected to execute")
        return nil
    }

    func query<M: Model>(
        _ modelType: M.Type,
        modelSchema: ModelSchema,
        condition: QueryPredicate?,
        sort: [QuerySortDescriptor]?,
        paginationInput: QueryPaginationInput?,
        eagerLoad: Bool
    ) -> Swift.Result<[M], DataStoreError> {
        if let responder = responders[.queryModelTypePredicate]
            as? QueryModelTypePredicateResponder<M> {
            return responder(modelType, condition)
        }

        return .success([])
    }

    func queryMutationSyncMetadata(for modelId: String, modelName: String) throws -> MutationSyncMetadata? {
        if let responder = responders[.queryMutationSyncMetadata] as? QueryMutationSyncMetadataResponder {
            return try responder(modelId)
        }

        if let err = errorToThrowOnMutationSyncMetadata {
            errorToThrowOnMutationSyncMetadata = nil
            throw err
        }
        return resultForQueryMutationSyncMetadata
    }

    func queryMutationSyncMetadata(for modelIds: [String], modelName: String) throws -> [MutationSyncMetadata] {
        if let responder = responders[.queryMutationSyncMetadatas] as? QueryMutationSyncMetadatasResponder {
            return try responder(modelIds)
        }

        if let err = errorToThrowOnMutationSyncMetadata {
            errorToThrowOnMutationSyncMetadata = nil
            throw err
        }
        return resultForQueryMutationSyncMetadatas
    }

    func queryModelSyncMetadata(for modelSchema: ModelSchema) throws -> ModelSyncMetadata? {
        listenerForModelSyncMetadata?()
        return resultForQueryModelSyncMetadata
    }

    func transaction(_ basicClosure: () throws -> Void) throws {
        if let err = errorToThrowOnTransaction {
            errorToThrowOnTransaction = nil
            throw err
        }
        try basicClosure()
    }

    func clear(completion: @escaping DataStoreCallback<Void>) {

    }

    func shouldIgnoreError(error: DataStoreError) -> Bool {
        return shouldIgnoreError
    }

    func removeStore(for modelSchema: ModelSchema) throws -> String {
        XCTFail("Not expected to execute")
        return ""
    }

    func createStore(for modelSchema: ModelSchema) throws -> String {
        XCTFail("Not expected to execute")
        return ""
    }

    func emptyStore(for modelSchema: ModelSchema) throws -> String {
        XCTFail("Not expected to execute")
        return ""
    }

    func renameStore(from: ModelSchema, toModelSchema: ModelSchema) throws -> String {
        XCTFail("Not expected to execute")
        return ""
    }
}

class MockStorageEngineBehavior: StorageEngineBehavior {

    static let mockStorageEngineBehaviorFactory =
        MockStorageEngineBehavior.init(isSyncEnabled:dataStoreConfiguration:validAPIPluginKey:validAuthPluginKey:modelRegistryVersion:userDefault:)
    var responders = [ResponderKeys: Any]()

    init() {
    }

    init(isSyncEnabled: Bool,
         dataStoreConfiguration: DataStoreConfiguration,
         validAPIPluginKey: String = "awsAPIPlugin",
         validAuthPluginKey: String = "awsCognitoAuthPlugin",
         modelRegistryVersion: String,
         userDefault: UserDefaults = UserDefaults.standard) throws {
    }

    func setupPublisher() {

    }

    var mockPublisher = PassthroughSubject<StorageEngineEvent, DataStoreError>()
    var publisher: AnyPublisher<StorageEngineEvent, DataStoreError> {
        mockPublisher.eraseToAnyPublisher()
    }

    func startSync(completion: @escaping DataStoreCallback<Void>) {
        completion(.successfulVoid)
        if let responder = responders[.startSync] as? StartSyncResponder {
            return responder("")
        }
    }

    func stopSync(completion: @escaping DataStoreCallback<Void>) {
        completion(.successfulVoid)
        if let responder = responders[.stopSync] as? StopSyncResponder {
            return responder("")
        }
    }

    func setUp(modelSchemas: [ModelSchema]) throws {
    }

    func applyModelMigrations(modelSchemas: [ModelSchema]) throws {
    }

    func query<M: Model>(
        _ modelType: M.Type,
        modelSchema: ModelSchema,
        withIdentifier identifier: ModelIdentifierProtocol,
        condition: QueryPredicate?,
        eagerLoad: Bool
    ) -> Swift.Result<M?, DataStoreError> {
        if let responder = responders[.query] as? QueryResponder<M> {
            return responder().map { $0.first }
        } else {
            return .success(nil)
        }
    }

    func query<M: Model>(
        _ modelType: M.Type,
        modelSchema: ModelSchema,
        condition: QueryPredicate?,
        sort: [QuerySortDescriptor]?,
        paginationInput: QueryPaginationInput?,
        eagerLoad: Bool
    ) -> Swift.Result<[M], DataStoreError> {
        if let responder = responders[.query] as? QueryResponder<M> {
            return responder()
        } else {
            return .success([])
        }
    }

    func save<M: Model>(
        _ model: M,
        modelSchema: ModelSchema,
        condition: QueryPredicate?,
        eagerLoad: Bool
    ) async -> Swift.Result<(M, MutationEvent.MutationType), DataStoreError> {
        .failure(DataStoreError(error: "Not expected to execute"))
    }

    func delete<M: Model>(
        _ modelType: M.Type,
        modelSchema: ModelSchema,
        withIdentifier identifier: ModelIdentifierProtocol,
        condition: QueryPredicate?
    ) async -> Swift.Result<M?, DataStoreError> {
        .success(nil)
    }

    func delete<M: Model>(
        _ modelType: M.Type,
        modelSchema: ModelSchema,
        condition: QueryPredicate
    ) async -> Swift.Result<[M], DataStoreError> {
        .failure(DataStoreError(error: "Not expected to execute"))
    }


    func clear(completion: @escaping DataStoreCallback<Void>) {
        completion(.successfulVoid)
        if let responder = responders[.clear] as? ClearResponder {
            return responder("")
        }
    }
}
