//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation
import AWSPluginsCore

/// Publishes a mutation event to the specified Cloud API. Upon receipt of the API response, validates to ensure it is
/// not a retriable error. If it is, attempts a retry until either success or terminal failure. Upon success or
/// terminal failure, publishes the event response to the appropriate ReconciliationQueue subject.
class SyncMutationToCloudOperation: Operation {

    private weak var api: APICategoryGraphQLBehavior?
    private let mutationEvent: MutationEvent
    private var mutationOperation: GraphQLOperation<MutationSync<AnyModel>>?
    private let completion: GraphQLOperation<MutationSync<AnyModel>>.EventListener

    init(mutationEvent: MutationEvent, api: APICategoryGraphQLBehavior,
         completion: @escaping GraphQLOperation<MutationSync<AnyModel>>.EventListener) {
        self.mutationEvent = mutationEvent
        self.api = api
        self.completion = completion

        super.init()
    }

    override func main() {
        log.verbose(#function)

        guard !isCancelled else {
            mutationOperation?.cancel()
            let apiError = APIError.unknown("Operation cancelled", "")
            finish(result: .failed(apiError))
            return
        }

        sendMutationToCloud()
    }

    private func sendMutationToCloud() {
        guard !isCancelled else {
            mutationOperation?.cancel()
            let apiError = APIError.unknown("Operation cancelled", "")
            finish(result: .failed(apiError))
            return
        }

        log.debug(#function)
        guard let api = api else {
            // TODO: This should be part of our error handling routines
            log.error("\(#function): API unexpectedly nil")
            let apiError = APIError.unknown("API unexpectedly nil", "")
            finish(result: .failed(apiError))
            return
        }

        guard let mutationType = GraphQLMutationType(rawValue: mutationEvent.mutationType) else {
            let dataStoreError = DataStoreError.decodingError(
                "Invalid mutation type",
                """
                The incoming mutation event had a mutation type of \(mutationEvent.mutationType), which does not
                match any known GraphQL mutation type. Ensure you only send valid mutation types:
                \(GraphQLMutationType.allCases)
                """
                )
            log.error(error: dataStoreError)
            return
        }

        let request: GraphQLRequest<MutationSync<AnyModel>>
        do {
            if mutationType == .delete {
                request = try deleteRequest(for: mutationEvent)
            } else {
                request = try createOrUpdateRequest(for: mutationEvent, mutationType: mutationType)
            }
        } catch {
            let apiError = APIError.unknown("Couldn't decode model", "", error)
            finish(result: .failed(apiError))
            return
        }

        log.verbose("\(#function) sending mutation with sync data: \(request)")
        mutationOperation = api.mutate(request: request) { asyncEvent in
            self.log.verbose("sendMutationToCloud received asyncEvent: \(asyncEvent)")
            self.validateResponseFromCloud(asyncEvent: asyncEvent)
        }
    }

    private func deleteRequest(for mutationEvent: MutationEvent)
        throws -> GraphQLRequest<MutationSync<AnyModel>> {
            let document = try MinimalGraphQLDeleteMutation(of: mutationEvent.modelName,
                                                            id: mutationEvent.modelId,
                                                            version: mutationEvent.version)
            let request = GraphQLRequest(document: document.stringValue,
                                         variables: document.variables,
                                         responseType: MutationSync<AnyModel>.self,
                                         decodePath: document.decodePath)
            return request
    }

    private func createOrUpdateRequest(for mutationEvent: MutationEvent, mutationType: GraphQLMutationType)
        throws -> GraphQLRequest<MutationSync<AnyModel>> {
            let model = try mutationEvent.decodeModel()
            let document = GraphQLSyncMutation(of: model,
                                               type: mutationType,
                                               version: mutationEvent.version)
            let request = GraphQLRequest(document: document.stringValue,
                                         variables: document.variables,
                                         responseType: MutationSync<AnyModel>.self,
                                         decodePath: document.decodePath)
            return request
    }

    private func validateResponseFromCloud(asyncEvent: AsyncEvent<Void,
        GraphQLResponse<MutationSync<AnyModel>>, APIError>) {
        guard !isCancelled else {
            mutationOperation?.cancel()
            let apiError = APIError.unknown("Operation cancelled", "")
            finish(result: .failed(apiError))
            return
        }

        // TODO: Wire in actual event validation and retriability

        // This doesn't belong here--need to add a `delete` API to the MutationEventSource and pass a
        // reference into the mutation queue.
        Amplify.DataStore.delete(mutationEvent) { result in
            switch result {
            case .failure(let dataStoreError):
                let apiError = APIError.pluginError(dataStoreError)
                self.finish(result: .failed(apiError))
            case .success:
                self.finish(result: asyncEvent)
            }
        }

    }

    private func finish(result: AsyncEvent<Void, GraphQLResponse<MutationSync<AnyModel>>, APIError>) {
        mutationOperation?.removeListener()
        mutationOperation = nil

        DispatchQueue.global().async {
            self.completion(result)
        }
    }
}

extension SyncMutationToCloudOperation: DefaultLogger { }
