//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation

extension AWSDataStorePlugin: DataStoreSubscribeBehavior {

    @available(iOS 13.0, *)
    public var publisher: AnyPublisher<MutationEvent, DataStoreError> {
        let passthroughSubject = PassthroughSubject<MutationEvent, DataStoreError>()
        startSyncStorageEngine()
            .flatMapOnResult { _ in self.extractDataStorePublisher(self.dataStorePublisher) }
            .map(\.publisher)
            .exec { result in
                switch result {
                case .success(let publisher):
                    _ = publisher
                        .subscribe(on: DispatchQueue.global())
                        .receive(on: DispatchQueue.global())
                        .eraseToAnyPublisher()
                        .sink(receiveCompletion: { complete in
                            passthroughSubject.send(completion: complete)
                        }, receiveValue: { event in
                            passthroughSubject.send(event)
                        })
                case .failure(let error):
                    passthroughSubject.send(completion: .failure(error))
                }
            }

        return passthroughSubject.eraseToAnyPublisher()
    }

    @available(iOS 13.0, *)
    public func publisher<M: Model>(for modelType: M.Type) -> AnyPublisher<MutationEvent, DataStoreError> {
        return publisher(for: modelType.modelName)
    }

    @available(iOS 13.0, *)
    public func publisher(for modelName: ModelName) -> AnyPublisher<MutationEvent, DataStoreError> {
        return publisher.filter { $0.modelName == modelName }.eraseToAnyPublisher()
    }

    @available(iOS 13.0, *)
    public func observeQuery<M: Model>(for modelType: M.Type,
                                       where predicate: QueryPredicate? = nil,
                                       sort sortInput: QuerySortInput? = nil)
    -> AnyPublisher<DataStoreQuerySnapshot<M>, DataStoreError> {
        return observeQuery(for: modelType,
                            modelSchema: modelType.schema,
                            where: predicate,
                            sort: sortInput?.asSortDescriptors())
    }

    @available(iOS 13.0, *)
    public func observeQuery<M: Model>(for modelType: M.Type,
                                       modelSchema: ModelSchema,
                                       where predicate: QueryPredicate? = nil,
                                       sort sortInput: [QuerySortDescriptor]? = nil)
    -> AnyPublisher<DataStoreQuerySnapshot<M>, DataStoreError> {
        let passthroughSubject = PassthroughSubject<DataStoreQuerySnapshot<M>, DataStoreError>()
        startSyncStorageEngine()
            .flatMapOnResult { _ in self.extractDataStorePublisher(self.dataStorePublisher) }
            .flatMapOnResult { dataStorePublisher in
                self.extractDispatchedModelSyncedEvent(with: modelSchema.name).map { (dataStorePublisher, $0) }
            }
            .exec { result in
                switch result {
                case let .success((dataStorePublisher, dispatchedModelSyncedEvent)):
                    let operation = AWSDataStoreObserveQueryOperation(
                        modelType: modelType,
                        modelSchema: modelSchema,
                        predicate: predicate,
                        sortInput: sortInput,
                        storageEngine: self.storageEngine,
                        dataStorePublisher: dataStorePublisher,
                        dataStoreConfiguration: self.dataStoreConfiguration,
                        dispatchedModelSyncedEvent: dispatchedModelSyncedEvent
                    )

                    _ = operation.publisher
                        .receive(on: DispatchQueue.global())
                        .subscribe(on: DispatchQueue.global())
                        .eraseToAnyPublisher()
                        .sink { complete in
                            passthroughSubject.send(completion: complete)
                        } receiveValue: { value in
                            passthroughSubject.send(value)
                        }

                    self.operationQueue.addOperation(operation)
                case let .failure(error):
                    passthroughSubject.send(completion: .failure(error))
                }
            }

        return passthroughSubject.eraseToAnyPublisher()
    }

    private func extractDataStorePublisher(
        _ dataStorePublisher: ModelSubcriptionBehavior?
    ) -> Result<ModelSubcriptionBehavior, DataStoreError> {
        if let dataStorePublisher = dataStorePublisher {
            return .success(dataStorePublisher)
        }
        return .failure(DataStoreError.unknown(
            "`dataStorePublisher` is expected to exist for deployment targets >=iOS13.0",
            "", nil)
        )
    }

    private func extractDispatchedModelSyncedEvent(
        with modelSchemaName: String
    ) -> Result<AtomicValue<Bool>, DataStoreError> {
        if let dispatchedModelSyncedEvent = dispatchedModelSyncedEvents[modelSchemaName] {
            return .success(dispatchedModelSyncedEvent)
        }
        return .failure(DataStoreError.unknown(
            "`dispatchedModelSyncedEvent` is expected to exist for \(modelSchemaName)",
            "", nil))
    }

}
