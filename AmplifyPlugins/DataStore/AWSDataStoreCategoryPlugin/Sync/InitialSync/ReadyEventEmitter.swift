//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Combine

@available(iOS 13.0, *)
final class ReadyEventEmitter {
    var readySink: AnyCancellable?
    let completion: BasicClosure
    init(remoteSyncEnginePublisher: AnyPublisher<RemoteSyncEngineEvent, DataStoreError>,
         completion: @escaping BasicClosure) {
        self.completion = completion
        let queriesReadyPublisher = ReadyEventEmitter.makeSyncQueriesReadyPublisher()
        let syncEngineStartedPublisher = ReadyEventEmitter.makeRemoteSyncEngineStartedPublisher(
            remoteSyncEnginePublisher: remoteSyncEnginePublisher
        )
        readySink = Publishers
            .Merge(queriesReadyPublisher, syncEngineStartedPublisher)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    self.dispatchReady()
                case .failure(let dataStoreError):
                    self.log.error("Failed to emit ready event, error: \(dataStoreError)")
                }
                self.completion()
            }, receiveValue: { _ in })
    }

    private static func makeSyncQueriesReadyPublisher() -> AnyPublisher<Void, DataStoreError> {
        Amplify.Hub
            .publisher(for: .dataStore)
            .filter { $0.eventName == HubPayload.EventName.DataStore.syncQueriesReady }
            .first()
            .map { _ in () }
            .setFailureType(to: DataStoreError.self)
            .eraseToAnyPublisher()
    }

    private static func makeRemoteSyncEngineStartedPublisher(
        remoteSyncEnginePublisher: AnyPublisher<RemoteSyncEngineEvent, DataStoreError>
    ) -> AnyPublisher<Void, DataStoreError> {
        remoteSyncEnginePublisher
            .filter { if case .syncStarted = $0 { return true } else { return false } }
            .first()
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    private func dispatchReady() {
        let readyEventPayload = HubPayload(eventName: HubPayload.EventName.DataStore.ready)
        Amplify.Hub.dispatch(to: .dataStore, payload: readyEventPayload)
    }

}

@available(iOS 13.0, *)
extension ReadyEventEmitter: DefaultLogger { }
