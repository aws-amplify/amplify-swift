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
final class SyncEventEmitter {
    var syncOrchestratorSink: AnyCancellable?
    var reconciliationQueueSink: AnyCancellable?

    var modelSyncedEventEmitters: [String: ModelSyncedEventEmitter]
//    let downstream: Publishers.MergeMany<AnyPublisher<Never, Never>>
    var downstream: AnyCancellable?

    init(initialSyncOrchestrator: AWSInitialSyncOrchestrator?,
         reconciliationQueue: IncomingEventReconciliationQueue?) {
        self.modelSyncedEventEmitters = [String: ModelSyncedEventEmitter]()

        let syncableModels = ModelRegistry.models
            .filter { $0.schema.isSyncable }

        var publishers = [AnyPublisher<Never, Never>]()
        for syncableModel in syncableModels {
            let modelSyncedEventEmitter = ModelSyncedEventEmitter(modelType: syncableModel,
                                                                  initialSyncOrchestrator: initialSyncOrchestrator,
                                                                  reconciliationQueue: reconciliationQueue)
            modelSyncedEventEmitters[syncableModel.modelName] = modelSyncedEventEmitter
            publishers.append(modelSyncedEventEmitter.publisher)
        }

        self.downstream = Publishers.MergeMany(publishers).sink(receiveCompletion: { [weak self] _ in
            self?.dispatchSyncQueriesReady()
        }, receiveValue: { _ in })
    }

    private func dispatchSyncQueriesReady() {
        let syncQueriesReadyEventPayload = HubPayload(eventName: HubPayload.EventName.DataStore.syncQueriesReady)
        Amplify.Hub.dispatch(to: .dataStore, payload: syncQueriesReadyEventPayload)
    }
}

@available(iOS 13.0, *)
extension SyncEventEmitter: DefaultLogger { }
