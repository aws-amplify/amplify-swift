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
/// 1. When there is a "conditional request failed" error, then emit to the Hub a 'conditionalSaveFailed' event.
@available(iOS 13.0, *)
class ProcessMutationErrorFromCloudOperation: Operation {

    private let mutationEvent: MutationEvent
    private let error: GraphQLResponseError<MutationSync<AnyModel>>
    private let completion: (Result<Void, Error>) -> Void
    private var queryOperation: GraphQLOperation<MutationSync<AnyModel>?>?

    init(mutationEvent: MutationEvent,
         error: GraphQLResponseError<MutationSync<AnyModel>>,
         completion: @escaping (Result<Void, Error>) -> Void) {
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
            // TODO: Check for 'ConflictUnhandled', execute conflict handler configurated

            let hasConditionalRequestFailed = graphQLErrors.contains { (error) -> Bool in
                error.message.contains("conditional request failed")
            }

            if hasConditionalRequestFailed {
                let payload = HubPayload(eventName: HubPayload.EventName.DataStore.conditionalSaveFailed,
                                         data: mutationEvent)
                Amplify.Hub.dispatch(to: .dataStore, payload: payload)
            }
        }

        finish(result: .success(()))
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
