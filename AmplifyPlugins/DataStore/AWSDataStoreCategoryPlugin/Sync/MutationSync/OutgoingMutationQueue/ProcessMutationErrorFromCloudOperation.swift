//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation
import AWSPluginsCore

/// Checks the GraphQL error response for specific error scenarios related to data synchronziation to the local store.
/// 1. When there is a "conditional request failed" error, then query for the latest version of the model, update local
/// store.
@available(iOS 13.0, *)
class ProcessMutationErrorFromCloudOperation: AsynchronousOperation {

    private weak var api: APICategoryGraphQLBehavior?
    private weak var storageAdapter: StorageEngineAdapter?
    private let mutationEvent: MutationEvent
    private let error: GraphQLResponseError<MutationSync<AnyModel>>
    private let completion: (Result<Void, Error>) -> Void
    private var queryOperation: GraphQLOperation<MutationSync<AnyModel>?>?

    init(mutationEvent: MutationEvent,
         storageAdapter: StorageEngineAdapter,
         error: GraphQLResponseError<MutationSync<AnyModel>>,
         api: APICategoryGraphQLBehavior, completion: @escaping (Result<Void, Error>) -> Void) {
        self.api = api
        self.storageAdapter = storageAdapter
        self.mutationEvent = mutationEvent
        self.error = error
        self.completion = completion
        super.init()
    }

    override func main() {
        log.verbose(#function)

        guard !isCancelled else {
            queryOperation?.cancel()
            let apiError = DataStoreError.unknown("Operation cancelled", "")
            finish(result: .failure(apiError))
            return
        }

        processConditionalRequestFailed()
    }

    private func processConditionalRequestFailed() {
        if case let .error(graphQLErrors) = error {
            let hasConditionalRequestFailed = graphQLErrors.contains { (error) -> Bool in
                error.message.contains("conditional request failed")
            }

            if hasConditionalRequestFailed {
                queryLatestRemoteModel()
            } else {
                finish(result: .success(()))
            }
        } else {
            finish(result: .success(()))
        }
    }

    private func queryLatestRemoteModel() {
        guard let api = api else {
            log.error("\(#function): API unexpectedly nil")
            let apiError = APIError.unknown("API unexpectedly nil", "")
            finish(result: .failure(apiError))
            return
        }

        let apiRequest = GraphQLRequest<MutationSyncResult?>.query(modelName: mutationEvent.modelName,
                                                                   byId: mutationEvent.modelId)
        queryOperation = api.query(request: apiRequest) { [weak self] asyncEvent in
            self?.log.verbose("queryLatestRemote received asyncEvent: \(asyncEvent)")
            self?.saveIfResponseContainsModel(asyncEvent: asyncEvent)
        }
    }

    private func saveIfResponseContainsModel(
        asyncEvent: AsyncEvent<Void, GraphQLResponse<MutationSync<AnyModel>?>, APIError>) {

        guard !isCancelled else {
            queryOperation?.cancel()
            let apiError = APIError.unknown("Operation cancelled", "")
            finish(result: .failure(apiError))
            return
        }

        if case .completed(let response) = asyncEvent,
            case .success(let mutationSyncOptional) = response,
            let mutationSync = mutationSyncOptional {
            saveModel(mutationSync)
        }
    }

    private func saveModel(_ mutationSync: MutationSync<AnyModel>) {
        guard let storageAdapter = storageAdapter else {
            log.error("\(#function): StorageAdapter unexpectedly nil")
            let error = DataStoreError.unknown("StorageAdapter unexpectedly nil", "")
            finish(result: .failure(error))
            return
        }

        storageAdapter.save(untypedModel: mutationSync.model.instance) { [weak self] response in
            switch response {
            case .failure(let dataStoreError):
                let error = DataStoreError.internalOperation("DataStore failed to save", "", dataStoreError)
                self?.finish(result: .failure(error))
            case .success:
                self?.saveMetadata(storageAdapter: storageAdapter, syncMetadata: mutationSync.syncMetadata)
            }
        }
    }

    private func saveMetadata(storageAdapter: StorageEngineAdapter,
                              syncMetadata: MutationSyncMetadata) {
        storageAdapter.save(syncMetadata, condition: nil) { [weak self] result in
            let payload = HubPayload(eventName: HubPayload.EventName.DataStore.conditionalSaveFailed,
                                     data: self?.mutationEvent)
            Amplify.Hub.dispatch(to: .dataStore, payload: payload)

            switch result {
            case .failure(let dataStoreError):
                let error = DataStoreError.internalOperation("DataStore failed to save", "", dataStoreError)
                self?.finish(result: .failure(error))
            case .success:
                self?.finish(result: .success(()))
            }
        }
    }

    override func cancel() {
        queryOperation?.cancel()
        let error = DataStoreError.unknown("Operation cancelled", "")
        finish(result: .failure(error))
    }

    private func finish(result: Result<Void, Error>) {
        queryOperation?.removeListener()
        queryOperation = nil

        DispatchQueue.global().async {
            self.completion(result)
        }
    }

}

@available(iOS 13.0, *)
extension ProcessMutationErrorFromCloudOperation: DefaultLogger { }
