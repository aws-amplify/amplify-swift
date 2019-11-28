//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation

// TODO: Evaluate this operation's suitablility for reactive/state machine pattern

/// Publishes a mutation event to the specified Cloud API. Upon receipt of the API response, validates to ensure it is
/// not a retriable error. If it is, attempts a retry until either success or terminal failure. Upon success or
/// terminal failure, publishes the event response to the appropriate ReconciliationQueue subject.
class SyncMutationToCloudOperation: Operation {

    typealias MutationCloudResponse = AsyncEvent<Void, GraphQLResponse<AnyModel>, APIError>

    private weak var api: APICategoryGraphQLBehavior?
    private let mutationEvent: MutationEvent
    private var mutationOperation: GraphQLOperation<AnyModel>?

    init(mutationEvent: MutationEvent, api: APICategoryGraphQLBehavior) {
        self.mutationEvent = mutationEvent
        self.api = api

        super.init()
    }

    override func main() {
        log.verbose(#function)

        guard !isCancelled else {
            mutationOperation?.cancel()
            return
        }

        sendMutationToCloud()
    }

    private func sendMutationToCloud() {
        guard !isCancelled else {
            mutationOperation?.cancel()
            return
        }

        log.debug(#function)
        guard let api = api else {
            // TODO: This should be part of our error handling routines
            log.error("\(#function): API unexpectedly nil")
            return
        }

        let model: Model
        let anyModel: AnyModel
        do {
            model = try mutationEvent.decodeModel()
            anyModel = try model.eraseToAnyModel()
        } catch {
            log.error(error: error)
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

        mutationOperation = api.mutate(ofAnyModel: anyModel, type: mutationType) { asyncEvent in
            self.log.verbose("sendMutationToCloud received asyncEvent: \(asyncEvent)")
            self.validateResponseFromCloud(asyncEvent: asyncEvent)
        }
    }

    private func validateResponseFromCloud(asyncEvent: MutationCloudResponse) {
        guard !isCancelled else {
            mutationOperation?.cancel()
            return
        }

        // TODO: Wire in actual event validation and retriability

    }

}

extension SyncMutationToCloudOperation: DefaultLogger { }
