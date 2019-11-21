//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation

/// Given a subscription listener to a model, syncs incoming subscription events to the data store
class APISubscriptionListener<M: Model> {

    private let modelType: M.Type
    private let queue: OperationQueue
    private weak var storageAdapter: StorageEngineAdapter?

    init(modelType: M.Type,
         mutationType: GraphQLMutationType,
         storageAdapter: StorageEngineAdapter) {
        self.modelType = modelType
        self.storageAdapter = storageAdapter

        self.queue = OperationQueue()
        queue.name = "com.amazonaws.DataStore.APISubscriptionListener.\(modelType).\(mutationType)"
        queue.maxConcurrentOperationCount = 1
    }

    var log: Logger {
        Amplify.Logging.logger(forCategory: "APISubscriptionListener")
    }

    private func processEvent(event: GraphQLResponse<M>) {
        switch event {
        case .success(let model):
            reconcileAndSave(model)
        case .error(let graphQLErrors):
            log.error("Received graphQL errors for \(modelType): \(graphQLErrors)")
        case .partial(_, let graphQLErrors):
            log.warn("Received partial result for \(modelType): \(graphQLErrors)")
        case .transformationError(let rawResponse, let apiError):
            log.error("Received partial result for \(modelType): \(apiError); rawResponse: \(rawResponse)")
        }
    }

    private func reconcileAndSave(_ model: M) {
    }

    private func resolve(queryResult: DataStoreResult<[M]>) -> M? {
        return nil
    }
}

protocol SelfLogging {
    static var log: Logger { get }
    var log: Logger { get }
}

extension SelfLogging {
    static var log: Logger {
        Amplify.Logging.logger(forCategory: String(describing: self))
    }
    var log: Logger {
        type(of: self).log
    }
}
