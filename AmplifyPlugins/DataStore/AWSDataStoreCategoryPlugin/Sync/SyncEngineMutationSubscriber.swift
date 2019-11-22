//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

/// Receives incoming mutation events and syncs them to the cloud API. Processes one event at a time, to ensure we fully
/// resolve a given mutation event's lifecycle before attempting the next one.
class SyncEngineMutationSubscriber {
    let api: APICategoryGraphQLBehavior

    /// Holds the subscription to the upstream publisher that delivers mutation events.
    var subscription: Subscription?

    init(api: APICategoryGraphQLBehavior) {
        self.api = api
    }

    // MARK: - Sync

     func syncMutationToCloud(mutationEvent: MutationEvent) -> AnyPublisher<AnyModel, DataStoreError> {
        let anyModel: AnyModel
        do {
            let model = try ModelRegistry.decode(modelName: mutationEvent.modelName, from: mutationEvent.json)
            anyModel = AnyModel(model)
        } catch {
            let dataStoreError = DataStoreError.invalidOperation(causedBy: error)
            return Fail(error: dataStoreError).eraseToAnyPublisher()
        }

        guard let mutationType = GraphQLMutationType(rawValue: mutationEvent.mutationType) else {
            let apiError = APIError.operationError(
                "Invalid mutation type",
                """
                The mutationType '\(mutationEvent.mutationType)' does not correspond to the known mutation types of
                \(GraphQLMutationType.allCases)
                """
                )
            let dataStoreError = DataStoreError.api(apiError)
            return Fail(error: dataStoreError).eraseToAnyPublisher()
        }

        return Future { future in
            self.log.verbose("Syncing to cloud: \(mutationEvent)")
            _ = self.api.mutate(of: anyModel, type: mutationType) { mutationResponse in
                switch mutationResponse {
                case .completed(let graphQLResponse):
                    SyncEngineMutationSubscriber.resolve(future: future, graphQLResponse: graphQLResponse)
                case .failed(let apiError):
                    future(.failure(DataStoreError.api(apiError)))
                default:
                    break
                }
            }

        }.eraseToAnyPublisher()
    }
}
