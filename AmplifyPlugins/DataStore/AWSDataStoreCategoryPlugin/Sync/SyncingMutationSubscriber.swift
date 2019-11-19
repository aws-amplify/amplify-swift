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
    private var subscription: Subscription?

    init(api: APICategoryGraphQLBehavior) {
        self.api = api
    }

    // MARK: - Sync

    private func syncToCloud<M: Model>(model: M) -> Future<String, DataStoreError> {
        print("Syncing to cloud: \(model)")
        return Future { $0(.success("Synced")) }
//        let modelType = type(of: model)
//        let schema = modelType.schema
//        let document = modelType
//        let request = GraphQLRequest<M>(document: model,
//                                        variables: <#T##[String : Any]?#>,
//                                        responseType: <#T##Model.Protocol#>)
//        api.mutate(request: <#T##GraphQLRequest<Decodable>#>) { event in ... }
    }

}

// MARK: - Subscriber

extension SyncEngineMutationSubscriber: Subscriber {
    typealias Input = MutationEvent
    typealias Failure = DataStoreError

    /// Receives the subscription from the publisher and immediately requests one event
    func receive(subscription: Subscription) {
        self.subscription = subscription
        subscription.request(.max(1))
    }

    /// Receives one input event and submits it for syncing. Once its processing is complete, requests a new event from
    /// the subscription
    func receive(_ input: MutationEvent) -> Subscribers.Demand {
        return .none
    }

    /// Receives a completion from the publisher and releases the subscription
    func receive(completion: Subscribers.Completion<DataStoreError>) {
        // TODO: Log.info
        print("MySubscriber Received completion: \(completion)")

        // TODO: Does this need to notify anybody upstream to nil out the SyncEngineMutationSubscriber instance?
        subscription = nil
    }

}
