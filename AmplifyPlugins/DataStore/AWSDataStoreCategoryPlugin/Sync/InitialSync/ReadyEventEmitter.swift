//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Combine

@available(iOS 13.0, *)
final class ReadyEventEmitter {
    /// Two conditions should be met to emit one `ready` event:
    /// - receive one `syncQueriesReady` event
    /// - the state of remoteSyncEngine move to `syncStarted`
    let conditionCount = AtomicValue(initialValue: 0)
    let remoteSyncEnginePublisher: AnyPublisher<RemoteSyncEngineEvent, DataStoreError>
    var remoteEngineSink: AnyCancellable?
    var syncQueriesReadyEventSink: AnyCancellable?

    init(remoteSyncEnginePublisher: AnyPublisher<RemoteSyncEngineEvent, DataStoreError>) {
        self.remoteSyncEnginePublisher = remoteSyncEnginePublisher

        self.syncQueriesReadyEventSink = Amplify.Hub.publisher(for: .dataStore).sink { event in
            if case HubPayload.EventName.DataStore.syncQueriesReady = event.eventName {
                _ = self.conditionCount.increment()
                guard self.conditionCount.get() == 2 else {
                    return
                }
                self.dispatchReady()
            }
        }

        self.remoteEngineSink = remoteSyncEnginePublisher
            .sink(receiveCompletion: { _ in },
                  receiveValue: { value in
                    switch value {
                    case .syncStarted:
                        _ = self.conditionCount.increment()
                        guard self.conditionCount.get() == 2 else {
                            return
                        }
                        self.dispatchReady()
                    default:
                        break
                    }
            })
    }

    private func dispatchReady() {
        let readyEventPayload = HubPayload(eventName: HubPayload.EventName.DataStore.ready)
        Amplify.Hub.dispatch(to: .dataStore, payload: readyEventPayload)
    }

}
