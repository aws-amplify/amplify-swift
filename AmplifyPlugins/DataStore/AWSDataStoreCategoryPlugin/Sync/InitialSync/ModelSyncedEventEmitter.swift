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
/// Listens to events published by both the `InitialSyncOrchestrator` and `IncomingEventReconciliationQueue`,
/// and emits a `ModelSyncedEvent` when the initial sync is complete. This class expects
/// `InitialSyncOrchestrator` and `IncomingEventReconciliationQueue` to have matching counts
/// for the events they enqueue and process, respectively.
final class ModelSyncedEventEmitter {
    private let queue = DispatchQueue(label: "com.amazonaws.ModelSyncedEventEmitterQueue",
                                      target: DispatchQueue.global())

    private var syncOrchestratorSink: AnyCancellable?
    private var reconciliationQueueSink: AnyCancellable?

    private let modelSchema: ModelSchema
    private var recordsReceived: Int
    private var reconciledReceived: Int
    private var initialSyncOperationFinished: Bool

    private var modelSyncedEventBuilder: ModelSyncedEvent.Builder

    private var modelSyncedEventTopic: PassthroughSubject<Never, Never>
    var publisher: AnyPublisher<Never, Never> {
        return modelSyncedEventTopic.eraseToAnyPublisher()
    }

    init(modelSchema: ModelSchema,
         initialSyncOrchestrator: InitialSyncOrchestrator?,
         reconciliationQueue: IncomingEventReconciliationQueue?) {
        self.modelSchema = modelSchema
        self.recordsReceived = 0
        self.reconciledReceived = 0
        self.initialSyncOperationFinished = false

        self.modelSyncedEventBuilder = ModelSyncedEvent.Builder()

        self.modelSyncedEventTopic = PassthroughSubject<Never, Never>()

        self.syncOrchestratorSink = initialSyncOrchestrator?
            .publisher
            .receive(on: queue)
            .filter(filterSyncOperationEvent(_:))
            .sink(receiveCompletion: { _ in },
                  receiveValue: { [weak self] value in
                    self?.onReceiveSyncOperationEvent(value: value)
            })

        self.reconciliationQueueSink = reconciliationQueue?
            .publisher
            .receive(on: queue)
            .filter(filterReconciliationQueueEvent(_:))
            .sink(receiveCompletion: { _ in },
                  receiveValue: { [weak self] value in
                    self?.onReceiveReconciliationEvent(value: value)
            })
    }

    /// Filtering `InitialSyncOperationEvent`s that come from `InitialSyncOperation` of the same ModelType
    private func filterSyncOperationEvent(_ value: InitialSyncOperationEvent) -> Bool {
        switch value {
        case .started(let modelName, _):
            return modelSchema.name == modelName
        case .enqueued(let mutationSync):
            return modelSchema.name == mutationSync.model.modelName
        case .finished(let modelName):
            return modelSchema.name == modelName
        }
    }

    /// Filtering `IncomingEventReconciliationQueueEvent`s that come from `ReconciliationAndLocalSaveOperation`
    /// of the same ModelType
    private func filterReconciliationQueueEvent(_ value: IncomingEventReconciliationQueueEvent) -> Bool {
        switch value {
        case .mutationEventApplied(let event):
            return modelSchema.name == event.modelName
        case .mutationEventDropped(let modelName):
            return modelSchema.name == modelName
        default:
            return true
        }
    }

    private func onReceiveSyncOperationEvent(value: InitialSyncOperationEvent) {
        switch value {
        case .started(_, let syncType):
            modelSyncedEventBuilder.isFullSync = syncType == .fullSync ? true : false
            modelSyncedEventBuilder.isDeltaSync = !modelSyncedEventBuilder.isFullSync
        case .enqueued:
            recordsReceived += 1
        case .finished:
            initialSyncOperationFinished = true
            if recordsReceived == 0 {
                dispatchModelSyncedEvent()
            }
        }
    }

    private func onReceiveReconciliationEvent(value: IncomingEventReconciliationQueueEvent) {
        switch value {
        case .mutationEventApplied(let event):
            reconciledReceived += 1
            switch GraphQLMutationType(rawValue: event.mutationType) {
            case .create:
                modelSyncedEventBuilder.added += 1
            case .update:
                modelSyncedEventBuilder.updated += 1
            case .delete:
                modelSyncedEventBuilder.deleted += 1
            default:
                break
            }
            if initialSyncOperationFinished && reconciledReceived == recordsReceived {
                dispatchModelSyncedEvent()
            }
        case .mutationEventDropped:
            reconciledReceived += 1
        default:
            return
        }
    }

    private func dispatchModelSyncedEvent() {
        modelSyncedEventBuilder.modelName = modelSchema.name
        let modelSyncedEventPayload = HubPayload(eventName: HubPayload.EventName.DataStore.modelSynced,
                                                 data: modelSyncedEventBuilder.build())
        Amplify.Hub.dispatch(to: .dataStore, payload: modelSyncedEventPayload)
        modelSyncedEventTopic.send(completion: .finished)
    }

}

@available(iOS 13.0, *)
extension ModelSyncedEventEmitter: DefaultLogger { }
