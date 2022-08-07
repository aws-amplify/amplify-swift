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

    func delete<M: Model>(_ modelType: M.Type,
                          modelSchema: ModelSchema,
                          withId id: Model.Identifier,
                          condition: QueryPredicate? = nil,
                          completion: DataStoreCallback<M?>) {
        XCTFail("Not expected to execute")
    }

    func delete<M: Model>(_ modelType: M.Type,
                          modelSchema: ModelSchema,
                          filter: QueryPredicate,
                          completion: @escaping DataStoreCallback<[M]>) {
        XCTFail("Not expected to execute")
    }
    
    func delete<M: Model>(_ modelType: M.Type,
                          modelSchema: ModelSchema,
                          filter: QueryPredicate) async -> DataStoreResult<[M]> {
        XCTFail("Not expected to execute")
        return .success([])
    }
    
    func delete<M>(_ modelType: M.Type,
                   modelSchema: ModelSchema,
                   withIdentifier identifier: ModelIdentifierProtocol,
                   condition: QueryPredicate?, completion: @escaping DataStoreCallback<M?>) where M: Model {
        XCTFail("Not expected to execute")
    }

    func delete(untypedModelType modelType: Model.Type,
                modelSchema: ModelSchema,
                withId id: String,
                condition: QueryPredicate? = nil,
                completion: (Result<Void, DataStoreError>) -> Void) {
        if let responder = responders[.deleteUntypedModel] as? DeleteUntypedModelCompletionResponder {
            let result = responder.callback((modelType, id))
            completion(result)
            return
        }

        return shouldReturnErrorOnDeleteMutation
            ? completion(.failure(causedBy: DataStoreError.invalidModelName("DelMutate")))
            : completion(.emptyResult)
    }

    func query(modelSchema: ModelSchema,
               predicate: QueryPredicate?,
               completion: DataStoreCallback<[Model]>) {
        let result = resultForQuery ?? .failure(DataStoreError.invalidOperation(causedBy: nil))
        completion(result)
    }
    
    func query(modelSchema: ModelSchema,
               predicate: QueryPredicate?) async -> DataStoreResult<[Model]> {
        return resultForQuery ?? .failure(DataStoreError.invalidOperation(causedBy: nil))
    }
    
    @available(*, deprecated, message: "Use async version")
    func query<M: Model>(_ modelType: M.Type,
                         predicate: QueryPredicate?,
                         paginationInput: QueryPaginationInput?,
                         completion: DataStoreCallback<[M]>) {
        XCTFail("Not expected to execute")
    }
    
    func query<M: Model>(_ modelType: M.Type,
                         predicate: QueryPredicate?,
                         sort: [QuerySortDescriptor]?,
                         paginationInput: QueryPaginationInput?) async -> DataStoreResult<[M]> {
        XCTFail("Not expected to execute")
        return .success([])
    }

    func query<M: Model>(_ modelType: M.Type,
                         modelSchema: ModelSchema,
                         predicate: QueryPredicate?,
                         sort: [QuerySortDescriptor]?,
                         paginationInput: QueryPaginationInput?,
                         completion: (DataStoreResult<[M]>) -> Void) {
        XCTFail("Not expected to execute")
    }

    func query<M: Model>(_ modelType: M.Type,
                         modelSchema: ModelSchema,
                         predicate: QueryPredicate?,
                         sort: [QuerySortDescriptor]?,
                         paginationInput: QueryPaginationInput?) async -> DataStoreResult<[M]> {
        XCTFail("Not expected to execute")
        return .success([])
    }
    
    func queryMutationSync(for models: [Model], modelName: String) throws -> [MutationSync<AnyModel>] {
        XCTFail("Not expected to execute")
        return []
    }

    func exists(_ modelSchema: ModelSchema, withId id: Model.Identifier, predicate: QueryPredicate?) throws -> Bool {
        XCTFail("Not expected to execute")
        return true
    }

    func exists(_ modelSchema: ModelSchema, withIdentifier id: ModelIdentifierProtocol, predicate: QueryPredicate?) throws -> Bool {
        XCTFail("Not expected to execute")
        return true
    }
    
    func save(untypedModel: Model, completion: @escaping DataStoreCallback<Model>) {
        if let responder = responders[.saveUntypedModel] as? SaveUntypedModelResponder {
            responder.callback((untypedModel, completion))
            return
        }

        completion(resultForSave!)
    }

    @available(*, deprecated, message: "Use async version")
    func save<M: Model>(_ model: M,
                        condition: QueryPredicate?,
                        completion: @escaping DataStoreCallback<M>) {
        if let responder = responders[.saveModelCompletion] as? SaveModelCompletionResponder<M> {
            responder.callback((model, completion))
            return
        }

        return shouldReturnErrorOnSaveMetadata
            ? completion(.failure(DataStoreError.invalidModelName("forceError")))
            : completion(.success(model))
    }
    
    func save<M: Model>(_ model: M, condition: QueryPredicate?) async -> DataStoreResult<M> {
        return shouldReturnErrorOnSaveMetadata
            ? .failure(DataStoreError.invalidModelName("forceError"))
            : .success(model)
    }

    @available(*, deprecated, message: "Use async version")
    func save<M: Model>(_ model: M,
                        modelSchema: ModelSchema,
                        condition where: QueryPredicate?,
                        completion: @escaping DataStoreCallback<M>) {
        if let responder = responders[.saveModelCompletion] as? SaveModelCompletionResponder<M> {
            responder.callback((model, completion))
            return
        }

        return shouldReturnErrorOnSaveMetadata
            ? completion(.failure(DataStoreError.invalidModelName("forceError")))
            : completion(.success(model))
    }
    
    func save<M: Model>(_ model: M,
                        modelSchema: ModelSchema,
                        condition: QueryPredicate?) async -> DataStoreResult<M> {
        return shouldReturnErrorOnSaveMetadata
            ? .failure(DataStoreError.invalidModelName("forceError"))
            : .success(model)
    }

    func queryMutationSync(forAnyModel anyModel: AnyModel) throws -> MutationSync<AnyModel>? {
        XCTFail("Not expected to execute")
        return nil
    }

    func query<M: Model>(_ modelType: M.Type,
                         predicate: QueryPredicate?,
                         sort: [QuerySortDescriptor]?,
                         paginationInput: QueryPaginationInput?,
                         completion: DataStoreCallback<[M]>) {
        if let responder = responders[.queryModelTypePredicate]
            as? QueryModelTypePredicateResponder<M> {
            let result = responder.callback((modelType, predicate))
            completion(result)
            return
        }

        completion(.success([]))
    }

    func queryMutationSyncMetadata(for modelId: String, modelName: String) throws -> MutationSyncMetadata? {
        if let responder = responders[.queryMutationSyncMetadata] as? QueryMutationSyncMetadataResponder {
            return try responder.callback(modelId)
        }

        if let err = errorToThrowOnMutationSyncMetadata {
            errorToThrowOnMutationSyncMetadata = nil
            throw err
        }
        return resultForQueryMutationSyncMetadata
    }

    func queryMutationSyncMetadata(for modelIds: [String], modelName: String) throws -> [MutationSyncMetadata] {
        if let responder = responders[.queryMutationSyncMetadatas] as? QueryMutationSyncMetadatasResponder {
            return try responder.callback(modelIds)
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
            return responder.callback("")
        }
    }

    func stopSync(completion: @escaping DataStoreCallback<Void>) {
        completion(.successfulVoid)
        if let responder = responders[.stopSync] as? StopSyncResponder {
            return responder.callback("")
        }
    }

    func setUp(modelSchemas: [ModelSchema]) throws {
    }

    func applyModelMigrations(modelSchemas: [ModelSchema]) throws {
    }

    @available(*, deprecated, message: "Use async version")
    func save<M: Model>(_ model: M, condition: QueryPredicate?, completion: @escaping DataStoreCallback<M>) {
        XCTFail("Not expected to execute")
    }
    
    func save<M: Model>(_ model: M, condition: QueryPredicate?) async -> DataStoreResult<M> {
        XCTFail("Not expected to execute")
        return .success(model)
    }

    @available(*, deprecated, message: "Use async version")
    func save<M: Model>(_ model: M,
                        modelSchema: ModelSchema,
                        condition where: QueryPredicate?,
                        completion: @escaping DataStoreCallback<M>) {
        XCTFail("Not expected to execute")
    }
    
    func save<M: Model>(_ model: M,
                        modelSchema: ModelSchema,
                        condition: QueryPredicate?) async -> DataStoreResult<M> {
        XCTFail("Not expected to execute")
        return .success(model)
    }
    
    func delete<M: Model>(_ modelType: M.Type,
                          modelSchema: ModelSchema,
                          withId id: Model.Identifier,
                          condition: QueryPredicate?,
                          completion: DataStoreCallback<M?>) {
        completion(.success(nil))
    }

    func delete<M: Model>(_ modelType: M.Type,
                          modelSchema: ModelSchema,
                          filter: QueryPredicate,
                          completion: @escaping DataStoreCallback<[M]>) {
        XCTFail("Not expected to execute")
    }

    func delete<M>(_ modelType: M.Type,
                   modelSchema: ModelSchema,
                   filter: QueryPredicate) async -> DataStoreResult<[M]> where M : Model {
        XCTFail("Not expected to execute")
        return .success([])
    }
    
    func delete<M>(_ modelType: M.Type,
                   modelSchema: ModelSchema,
                   withIdentifier identifier: ModelIdentifierProtocol,
                   condition: QueryPredicate?,
                   completion: @escaping DataStoreCallback<M?>) where M: Model {
        completion(.success(nil))
    }
    
    @available(*, deprecated, message: "Use async version")
    func query<M: Model>(_ modelType: M.Type,
                         predicate: QueryPredicate?,
                         sort: [QuerySortDescriptor]?,
                         paginationInput: QueryPaginationInput?,
                         completion: DataStoreCallback<[M]>) {
        if let responder = responders[.query] as? QueryResponder<M> {
            let result = responder.callback(())
            completion(result)
        } else {
            completion(.success([]))
        }
    }
    
    func query<M: Model>(_ modelType: M.Type,
                         predicate: QueryPredicate?,
                         sort: [QuerySortDescriptor]?,
                         paginationInput: QueryPaginationInput?) async -> DataStoreResult<[M]> {
        if let responder = responders[.query] as? QueryResponder<M> {
            let result = responder.callback(())
            return result
        } else {
            return .success([])
        }
    }

    func query<M: Model>(_ modelType: M.Type,
                         modelSchema: ModelSchema,
                         predicate: QueryPredicate?,
                         sort: [QuerySortDescriptor]?,
                         paginationInput: QueryPaginationInput?,
                         completion: (DataStoreResult<[M]>) -> Void) {

        if let responder = responders[.query] as? QueryResponder<M> {
            let result = responder.callback(())
            completion(result)
        } else {
            completion(.success([]))
        }
    }
    
    func query<M>(_ modelType: M.Type,
                  modelSchema: ModelSchema,
                  predicate: QueryPredicate?,
                  sort: [QuerySortDescriptor]?,
                  paginationInput: QueryPaginationInput?) async -> DataStoreResult<[M]> where M : Model {
        if let responder = responders[.query] as? QueryResponder<M> {
            let result = responder.callback(())
            return result
        } else {
            return .success([])
        }
    }
    
    func clear(completion: @escaping DataStoreCallback<Void>) {
        completion(.successfulVoid)
        if let responder = responders[.clear] as? ClearResponder {
            return responder.callback("")
        }
    }
}
