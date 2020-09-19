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
final class ModelSyncedEventEmitter {
    var syncOrchestratorSink: AnyCancellable?
    var reconciliationQueueSink: AnyCancellable?

    let modelType: Model.Type
    var recordsReceived: Int
    var reconciledReceived: Int
    var initialSyncOpFinished: Bool

    private var modelSyncedEventBuilder: ModelSyncedEvent.Builder

    private var modelSyncedEventTopic: PassthroughSubject<Never, Never>
    var publisher: AnyPublisher<Never, Never> {
        return modelSyncedEventTopic.eraseToAnyPublisher()
    }

    init(modelType: Model.Type,
         initialSyncOrchestrator: AWSInitialSyncOrchestrator?,
         reconciliationQueue: IncomingEventReconciliationQueue?) {
        self.modelType = modelType
        self.recordsReceived = 0
        self.reconciledReceived = 0
        self.initialSyncOpFinished = false

        self.modelSyncedEventBuilder = ModelSyncedEvent.Builder()

        self.modelSyncedEventTopic = PassthroughSubject<Never, Never>()

        self.syncOrchestratorSink = initialSyncOrchestrator?
            .publisher
            .sink(receiveCompletion: { [weak self] completion in
                self?.onReceiveCompletion(completion: completion)
            }, receiveValue: { [weak self] value in
                self?.onReceiveSyncOperationEvent(value: value)
            })

        self.reconciliationQueueSink = reconciliationQueue?
            .publisher
            .sink(receiveCompletion: { [weak self] completion in
                self?.onReceiveCompletion(completion: completion)
            }, receiveValue: { [weak self] value in
                self?.onReceiveReconciliationEvent(value: value)
            })
    }

    private func onReceiveSyncOperationEvent(value: InitialSyncOperationEvent) {
        switch value {
        case .isFullSync(let modelType, let isFullSync):
            guard self.modelType == modelType else {
                return
            }
            log.info("\(#function): \(value)")
            modelSyncedEventBuilder.isFullSync = isFullSync
            modelSyncedEventBuilder.isDeltaSync = !isFullSync
        case .mutationSync(let mutationSync):
            guard modelType.modelName == mutationSync.model.modelName else {
                return
            }
            log.info("\(#function): \(value)")
            recordsReceived += 1
        case .finishedOffering(let modelName):
            guard modelType.modelName == modelName else {
                return
            }
            log.info("\(#function): \(value)")
            initialSyncOpFinished = true
        }
    }

    private func onReceiveReconciliationEvent(value: IncomingEventReconciliationQueueEvent) {
        log.info("\(#function): \(value)")
        switch value {
        case .mutationEvent(let event):
            guard event.modelName == modelType.modelName else {
                return
            }
            log.info("\(#function): \(value)")
            reconciledReceived += 1
            switch event.mutationType {
            case "create":
                _ = modelSyncedEventBuilder.createCount.increment()
            case "update":
                _ = modelSyncedEventBuilder.updateCount.increment()
            case "delete":
                _ = modelSyncedEventBuilder.deleteCount.increment()
            default:
                break
            }
            if initialSyncOpFinished == true && reconciledReceived == recordsReceived {
                dispatchModelSyncedEvent()
            }
        case .mutationEventDropped(let name):
            guard name == modelType.modelName else {
                return
            }
            log.info("\(#function): \(value)")
            reconciledReceived += 1
        default:
            return
        }
    }

    private func onReceiveCompletion(completion: Subscribers.Completion<DataStoreError>) {
        log.info("\(#function): \(completion)")
    }

    private func dispatchModelSyncedEvent() {
        modelSyncedEventBuilder.modelName = modelType.modelName
        let modelSyncedEventPayload = HubPayload(eventName: HubPayload.EventName.DataStore.modelSynced,
                                                 data: modelSyncedEventBuilder.build())
        Amplify.Hub.dispatch(to: .dataStore, payload: modelSyncedEventPayload)
        modelSyncedEventTopic.send(completion: .finished)
    }

}

@available(iOS 13.0, *)
extension ModelSyncedEventEmitter: DefaultLogger { }
