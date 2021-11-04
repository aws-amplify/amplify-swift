//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation

@available(iOS 13.0, *)
extension RemoteSyncEngine {
    func onReceiveCompletion(receiveCompletion: Subscribers.Completion<DataStoreError>) {
        switch stateMachine.state {
        case .initializingSubscriptions:
            notifyError(receiveCompletion: receiveCompletion)
        case .syncEngineActive:
            notifyError(receiveCompletion: receiveCompletion)
        default:
            break
        }
    }

    func notifyError(receiveCompletion: Subscribers.Completion<DataStoreError>) {
        switch receiveCompletion {
        case .failure(let error):
            stateMachine.notify(action: .errored(error))
        case .finished:
            stateMachine.notify(action: .finished)
        }
    }

    func onReceive(receiveValue: IncomingEventReconciliationQueueEvent) {
        switch receiveValue {
        case .initialized:
            let payload = HubPayload(eventName: HubPayload.EventName.DataStore.subscriptionsEstablished)
            Amplify.Hub.dispatch(to: .dataStore, payload: payload)
            remoteSyncTopicPublisher.send(.subscriptionsInitialized)
            stateMachine.notify(action: .initializedSubscriptions)
        case .started:
            remoteSyncTopicPublisher.send(.subscriptionsActivated)
            if let api = self.api {
                stateMachine.notify(action: .activatedCloudSubscriptions(api,
                                                                         mutationEventPublisher))
            }
        case .paused:
            remoteSyncTopicPublisher.send(.subscriptionsPaused)
        case .mutationEventDropped, .mutationEventApplied:
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
