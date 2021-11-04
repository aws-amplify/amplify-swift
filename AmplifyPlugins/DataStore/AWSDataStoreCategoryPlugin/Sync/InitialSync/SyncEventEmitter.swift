//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Combine
import Foundation

enum IncomingSyncEventEmitterEvent {
    case mutationEventApplied(MutationEvent)
    case mutationEventDropped(modelName: String)
    case modelSyncedEvent(ModelSyncedEvent)
    case syncQueriesReadyEvent
}

/// SyncEventEmitter holds onto one ModelSyncedEventEmitter per model. It counts the number of `modelSyncedEvent` to
/// emit the `syncQueriesReady` and sends back the reconciliation events (`.mutationEventApplied`,
/// `.mutationEventDropped`) to its subscribers.
@available(iOS 13.0, *)
final class SyncEventEmitter {
    private let queue = DispatchQueue(label: "com.amazonaws.SyncEventEmitter",
                                      target: DispatchQueue.global())

    var modelSyncedEventEmitters: [String: ModelSyncedEventEmitter]
    var initialSyncCompleted: AnyCancellable?

    private var syncableModels: Int
    private var modelSyncedReceived: Int

    private var syncEventEmitterTopic: PassthroughSubject<IncomingSyncEventEmitterEvent, Never>
    var publisher: AnyPublisher<IncomingSyncEventEmitterEvent, Never> {
        return syncEventEmitterTopic.eraseToAnyPublisher()
    }

    var shouldDispatchSyncQueriesReadyEvent: Bool {
        syncableModels == modelSyncedReceived
    }

    init(initialSyncOrchestrator: InitialSyncOrchestrator?,
         reconciliationQueue: IncomingEventReconciliationQueue?) {
        self.modelSyncedEventEmitters = [String: ModelSyncedEventEmitter]()
        self.syncEventEmitterTopic = PassthroughSubject<IncomingSyncEventEmitterEvent, Never>()
        self.modelSyncedReceived = 0

        let syncableModelSchemas = ModelRegistry.modelSchemas.filter { $0.isSyncable }
        self.syncableModels = syncableModelSchemas.count

        var publishers = [AnyPublisher<IncomingModelSyncedEmitterEvent, Never>]()
        for syncableModelSchema in syncableModelSchemas {
            let modelSyncedEventEmitter = ModelSyncedEventEmitter(modelSchema: syncableModelSchema,
                                                                  initialSyncOrchestrator: initialSyncOrchestrator,
                                                                  reconciliationQueue: reconciliationQueue)
            modelSyncedEventEmitters[syncableModelSchema.name] = modelSyncedEventEmitter
            publishers.append(modelSyncedEventEmitter.publisher)
        }

        self.initialSyncCompleted = Publishers
            .MergeMany(publishers)
            .receive(on: queue)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { [weak self] value in
                self?.onReceiveModelSyncedEmitterEvent(value: value)
            })
    }

    private func onReceiveModelSyncedEmitterEvent(value: IncomingModelSyncedEmitterEvent) {
        switch value {
        case .mutationEventApplied(let mutationEvent):
            syncEventEmitterTopic.send(.mutationEventApplied(mutationEvent))
        case .mutationEventDropped(let modelName):
            syncEventEmitterTopic.send(.mutationEventDropped(modelName: modelName))
        case .modelSyncedEvent(let modelSyncedEvent):
            modelSyncedReceived += 1
            syncEventEmitterTopic.send(.modelSyncedEvent(modelSyncedEvent))
            if shouldDispatchSyncQueriesReadyEvent {
                syncEventEmitterTopic.send(.syncQueriesReadyEvent)
            }
        }
    }
}

@available(iOS 13.0, *)
extension SyncEventEmitter: DefaultLogger { }
