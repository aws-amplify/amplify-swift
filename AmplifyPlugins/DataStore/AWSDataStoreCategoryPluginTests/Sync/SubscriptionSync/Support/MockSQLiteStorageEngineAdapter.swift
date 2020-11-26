//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSPluginsCore
import Combine

@testable import Amplify
@testable import AWSDataStoreCategoryPlugin

class MockSQLiteStorageEngineAdapter: StorageEngineAdapter {

    var responders = [ResponderKeys: Any]()

    var resultForQuery: DataStoreResult<[Model]>?
    var resultForSave: DataStoreResult<Model>?

    var resultForQueryMutationSyncMetadata: MutationSyncMetadata?
    var errorToThrowOnMutationSyncMetadata: DataStoreError?

    var shouldReturnErrorOnSaveMetadata: Bool
    var shouldReturnErrorOnDeleteMutation: Bool

    var resultForQueryModelSyncMetadata: ModelSyncMetadata?
    var listenerForModelSyncMetadata: BasicClosure?

    init() {
        self.shouldReturnErrorOnSaveMetadata = false
        self.shouldReturnErrorOnDeleteMutation = false
    }

    func setUp(modelSchemas: [ModelSchema]) throws {
        XCTFail("Not expected to execute")
    }

    // MARK: - Responses

    func returnOnQuery(dataStoreResult: DataStoreResult<[Model]>?) {
        resultForQuery = dataStoreResult
    }

    func returnOnQueryMutationSyncMetadata(_ mutationSyncMetadata: MutationSyncMetadata?) {
        resultForQueryMutationSyncMetadata = mutationSyncMetadata
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

    // MARK: - StorageEngineAdapter

    func delete<M: Model>(_ modelType: M.Type,
                          modelSchema: ModelSchema,
                          withId id: Model.Identifier,
                          completion: DataStoreCallback<M?>) {
        XCTFail("Not expected to execute")
    }

    func delete<M: Model>(_ modelType: M.Type,
                          modelSchema: ModelSchema,
                          predicate: QueryPredicate,
                          completion: @escaping DataStoreCallback<[M]>) {
        XCTFail("Not expected to execute")
    }

    func delete(untypedModelType modelType: Model.Type,
                modelSchema: ModelSchema,
                withId id: String,
                completion: (Result<Void, DataStoreError>) -> Void) {
        if let responder = responders[.deleteUntypedModel] as? DeleteUntypedModelCompletionResponder {
            responder.callback((modelType, id))
            completion(.emptyResult)
            return
        }

        return shouldReturnErrorOnDeleteMutation
            ? completion(.failure(causedBy: DataStoreError.invalidModelName("DelMutate")))
            : completion(.emptyResult)
    }

    func query(untypedModel modelType: Model.Type,
               predicate: QueryPredicate?,
               completion: DataStoreCallback<[Model]>) {
        let result = resultForQuery ?? .failure(DataStoreError.invalidOperation(causedBy: nil))
        completion(result)
    }

    func query<M: Model>(_ modelType: M.Type,
                         predicate: QueryPredicate?,
                         paginationInput: QueryPaginationInput?,
                         completion: DataStoreCallback<[M]>) {
        XCTFail("Not expected to execute")
    }

    func query<M: Model>(_ modelType: M.Type,
                         modelSchema: ModelSchema,
                         predicate: QueryPredicate?,
                         sort: [QuerySortDescriptor]?,
                         paginationInput: QueryPaginationInput?,
                         completion: (DataStoreResult<[M]>) -> Void) {
        XCTFail("Not expected to execute")
    }

    func queryMutationSync(for models: [Model]) throws -> [MutationSync<AnyModel>] {
        XCTFail("Not expected to execute")
        return []
    }

    func exists(_ modelSchema: ModelSchema, withId id: Model.Identifier, predicate: QueryPredicate?) throws -> Bool {
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

    func queryMutationSyncMetadata(for modelId: String) throws -> MutationSyncMetadata? {
        if let responder = responders[.queryMutationSyncMetadata] as? QueryMutationSyncMetadataResponder {
            return try responder.callback(modelId)
        }

        if let err = errorToThrowOnMutationSyncMetadata {
            errorToThrowOnMutationSyncMetadata = nil
            throw err
        }
        return resultForQueryMutationSyncMetadata
    }

    func queryModelSyncMetadata(for modelSchema: ModelSchema) throws -> ModelSyncMetadata? {
        listenerForModelSyncMetadata?()
        return resultForQueryModelSyncMetadata
    }

    func transaction(_ basicClosure: () throws -> Void) throws {
        XCTFail("Not expected to execute")
    }
    func clear(completion: @escaping DataStoreCallback<Void>) {
        XCTFail("Not expected to execute")
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

    var publisher: AnyPublisher<StorageEngineEvent, DataStoreError> {
        return PassthroughSubject<StorageEngineEvent, DataStoreError>().eraseToAnyPublisher()
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

    func save<M: Model>(_ model: M, condition: QueryPredicate?, completion: @escaping DataStoreCallback<M>) {
        XCTFail("Not expected to execute")
    }

    func save<M: Model>(_ model: M,
                        modelSchema: ModelSchema,
                        condition where: QueryPredicate?,
                        completion: @escaping DataStoreCallback<M>) {
        XCTFail("Not expected to execute")
    }

    func delete<M: Model>(_ modelType: M.Type,
                          modelSchema: ModelSchema,
                          withId id: Model.Identifier,
                          completion: DataStoreCallback<M?>) {
        completion(.success(nil))
    }

    func delete<M: Model>(_ modelType: M.Type,
                          modelSchema: ModelSchema,
                          predicate: QueryPredicate,
                          completion: @escaping DataStoreCallback<[M]>) {
        XCTFail("Not expected to execute")
    }

    func query<M: Model>(_ modelType: M.Type,
                         predicate: QueryPredicate?,
                         sort: [QuerySortDescriptor]?,
                         paginationInput: QueryPaginationInput?,
                         completion: DataStoreCallback<[M]>) {
        completion(.success([]))
        if let responder = responders[.query] as? QueryResponder {
            return responder.callback("")
        }
    }

    func query<M: Model>(_ modelType: M.Type,
                         modelSchema: ModelSchema,
                         predicate: QueryPredicate?,
                         sort: [QuerySortDescriptor]?,
                         paginationInput: QueryPaginationInput?,
                         completion: (DataStoreResult<[M]>) -> Void) {
        completion(.success([]))
        if let responder = responders[.query] as? QueryResponder {
            return responder.callback("")
        }
    }

    func clear(completion: @escaping DataStoreCallback<Void>) {
        completion(.successfulVoid)
        if let responder = responders[.clear] as? ClearResponder {
            return responder.callback("")
        }
    }
}
