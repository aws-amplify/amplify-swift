//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation

extension RemoteSyncEngine {
    func onReceiveCompletion(receiveCompletion: Subscribers.Completion<DataStoreError>) {
        notifyError(receiveCompletion: receiveCompletion)
    }

    func notifyError(receiveCompletion: Subscribers.Completion<DataStoreError>) {
        let action: Action
        switch receiveCompletion {
        case .failure(let error):
            action = .errored(error)
        case .finished:
            action = .finished
        }
        // Checked with the state, so a state that has just changed can't get an action it doesn't handle
        stateMachine.notify(action: action, if: Self.hasSubscriptions)
    }

    /// The states that have subscriptions, so losing them mid-startup ends that startup instead of stalling it
    static func hasSubscriptions(_ state: State) -> Bool {
        switch state {
        case .initializingSubscriptions,
             .performingInitialSync,
             .activatingCloudSubscriptions,
             .activatingMutationQueue,
             .notifyingSyncStarted,
             .syncEngineActive:
            return true
        default:
            return false
        }
    }

    func onReceive(receiveValue: IncomingEventReconciliationQueueEvent) {
        switch receiveValue {
        case .initialized:
            log.verbose("[InitializeSubscription.5] RemoteSyncEngine IncomingEventReconciliationQueueEvent.initialized")
            log.verbose("[Lifecycle event 1]: subscriptionsEstablished")
            let payload = HubPayload(eventName: HubPayload.EventName.DataStore.subscriptionsEstablished)
            Amplify.Hub.dispatch(to: .dataStore, payload: payload)
            remoteSyncTopicPublisher.send(.subscriptionsInitialized)
            stateMachine.notify(action: .initializedSubscriptions)
        case .started:
            log.verbose("[InitializeSubscription.6] RemoteSyncEngine IncomingEventReconciliationQueueEvent.started")
            guard let api else {
                let error = DataStoreError.internalOperation("api is unexpectedly `nil`", "", nil)
                stateMachine.notify(action: .errored(error))
                return
            }
            remoteSyncTopicPublisher.send(.subscriptionsActivated)
            stateMachine.notify(action: .activatedCloudSubscriptions(
                api,
                mutationEventPublisher,
                reconciliationQueue
            ))
        case .paused:
            remoteSyncTopicPublisher.send(.subscriptionsPaused)
        case .idle, .mutationEventDropped, .mutationEventApplied:
            break
        }
    }

    func onReceive(receiveValue: IncomingSyncEventEmitterEvent) {
        switch receiveValue {
        case .mutationEventApplied(let mutationEvent):
            remoteSyncTopicPublisher.send(.mutationEvent(mutationEvent))
        case .mutationEventDropped:
            break
        case .modelSyncedEvent(let modelSyncedEvent):
            remoteSyncTopicPublisher.send(.modelSyncedEvent(modelSyncedEvent))
        case .syncQueriesReadyEvent:
            remoteSyncTopicPublisher.send(.syncQueriesReadyEvent)
        }
    }

    func onReceive(receiveValue: IncomingReadyEventEmitter) {
        switch receiveValue {
        case .readyEvent:
            remoteSyncTopicPublisher.send(.readyEvent)
        }
    }
}
