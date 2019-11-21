//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

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
    func receive(_ mutationEvent: MutationEvent) -> Subscribers.Demand {

        // The `sink` completion handlers below must hold onto this reference, or else Combine cancels it when the
        // method returns. To prevent retains, be sure to set the subscription to `nil` inside each of the sink
        // `receive` events
        var mutationSyncSubscription: AnyCancellable?

        mutationSyncSubscription = syncMutationToCloud(mutationEvent: mutationEvent).sink(
            receiveCompletion: { completion in
                self.log.verbose("mutationSyncSubscription.receiveCompletion: \(completion)")
                mutationSyncSubscription?.cancel()
                mutationSyncSubscription = nil
        },
            receiveValue: { value in
                self.log.verbose("mutationSyncSubscription.receiveValue: \(value)")
                let payload = HubPayload(eventName: HubPayload.EventName.DataStore.mutationSyncReceived,
                                         context: nil,
                                         data: value)
                Amplify.Hub.dispatch(to: .dataStore, payload: payload)
                self.subscription?.request(.max(1))
                mutationSyncSubscription?.cancel()
                mutationSyncSubscription = nil
        })

        // Return `.none` from this method, because we don't want to request a new input until after we've fully
        // resolved the current one. That resolution may include network traffic, conflict resolution, and error
        // retries
        return .none
    }

    /// Receives a completion from the publisher and releases the subscription
    func receive(completion: Subscribers.Completion<DataStoreError>) {
        log.info("SyncEngineMutationSubscriber.receiveCompletion: \(completion)")

        // TODO: Does this need to notify anybody upstream to nil out the SyncEngineMutationSubscriber instance?
        subscription = nil
    }

}
