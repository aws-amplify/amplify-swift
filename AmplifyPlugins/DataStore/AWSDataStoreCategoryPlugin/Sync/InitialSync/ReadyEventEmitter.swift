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
    let dispatchReadyGroup = DispatchGroup()
    let publisher: AnyPublisher<RemoteSyncEngineEvent, DataStoreError>
    var remoteEngineSink: AnyCancellable?
    var syncQueriesReadyEventSink: AnyCancellable?

    init(publisher: AnyPublisher<RemoteSyncEngineEvent, DataStoreError>) {
        self.publisher = publisher
    }

    func configure() {
        syncQueriesReadyEventSink = Amplify.Hub.publisher(for: .dataStore).sink { event in
            if case HubPayload.EventName.DataStore.syncQueriesReady = event.eventName {
                self.dispatchReadyGroup.leave()
            }
        }

        remoteEngineSink = publisher
            .sink(receiveCompletion: { _ in },
                  receiveValue: { value in
                    switch value {
                    case .syncStarted:
                        self.dispatchReadyGroup.leave()
                    default:
                        break
                    }
            })

        dispatchReadyGroup.enter()
        dispatchReadyGroup.enter()

        dispatchReadyGroup.notify(queue: .global()) {
            self.dispatchReady()
        }
    }

    private func dispatchReady() {
        let readyEventPayload = HubPayload(eventName: HubPayload.EventName.DataStore.ready)
        Amplify.Hub.dispatch(to: .dataStore, payload: readyEventPayload)
    }

}
