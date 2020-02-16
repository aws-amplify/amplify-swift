//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation

@available(iOS 13.0, *)
extension RemoteSyncEngine {
    @available(iOS 13.0, *)
    func onReceiveCompletion(receiveCompletion: Subscribers.Completion<DataStoreError>) {
        let semaphore = DispatchSemaphore(value: 1)
        semaphore.wait()
        if case .syncEngineActive = stateMachine.state {
            switch receiveCompletion {
            case .failure(let error):
                stateMachine.notify(action: .errored(error))
            case .finished:
                stateMachine.notify(action: .errored(nil))
            }
        }
        semaphore.signal()
    }

    @available(iOS 13.0, *)
    func onReceive(receiveValue: IncomingEventReconciliationQueueEvent) {
        switch receiveValue {
        case .started:
            remoteSyncTopicPublisher.send(.subscriptionsActivated)
            if let api = self.api {
                stateMachine.notify(action: .activatedCloudSubscriptions(api, mutationEventPublisher))
            }
        case .paused:
            remoteSyncTopicPublisher.send(.subscriptionsPaused)
        case .mutationEvent(let mutationEvent):
            remoteSyncTopicPublisher.send(.mutationEvent(mutationEvent))
        }
    }
}
