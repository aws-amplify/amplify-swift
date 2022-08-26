//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

extension AWSDataStorePlugin: DataStoreSubscribeBehavior {

    public var publisher: AnyPublisher<MutationEvent, DataStoreError> {
        initStorageEngineAndStartSync()
        // Force-unwrapping: The optional 'dataStorePublisher' is expected
        // to exist for deployment targets >=iOS13.0
        return dataStorePublisher!.publisher
    }

//    public func publisher<M: Model>(for modelType: M.Type) -> AnyPublisher<MutationEvent, DataStoreError> {
//        return publisher(for: modelType.modelName)
//    }

    public func publisher(for modelName: ModelName) -> AnyPublisher<MutationEvent, DataStoreError> {
        return publisher.filter { $0.modelName == modelName }.eraseToAnyPublisher()
    }

    public func observe<M: Model>(for modelType: M.Type) -> AmplifyAsyncThrowingSequence<MutationEvent> {
        let runner = ObserveTaskRunner(publisher: publisher(for: modelType.modelName))
        return runner.sequence
    }
    
    public func observeQuery<M: Model>(for modelType: M.Type,
                                       where predicate: QueryPredicate? = nil,
                                       sort sortInput: QuerySortInput? = nil)
    -> AnyPublisher<DataStoreQuerySnapshot<M>, DataStoreError> {
        return observeQuery(for: modelType,
                            modelSchema: modelType.schema,
                            where: predicate,
                            sort: sortInput?.asSortDescriptors())
    }

    public func observeQuery<M: Model>(for modelType: M.Type,
                                       modelSchema: ModelSchema,
                                       where predicate: QueryPredicate? = nil,
                                       sort sortInput: [QuerySortDescriptor]? = nil)
    -> AnyPublisher<DataStoreQuerySnapshot<M>, DataStoreError> {
        initStorageEngineAndStartSync()

        guard let dataStorePublisher = dataStorePublisher else {
            return Fail(error: DataStoreError.unknown(
                            "`dataStorePublisher` is expected to exist for deployment targets >=iOS13.0",
                            "", nil)).eraseToAnyPublisher()
        }
        guard let dispatchedModelSyncedEvent = dispatchedModelSyncedEvents[modelSchema.name] else {
            return Fail(error: DataStoreError.unknown(
                            "`dispatchedModelSyncedEvent` is expected to exist for \(modelSchema.name)",
                            "", nil)).eraseToAnyPublisher()
        }
        let operation = AWSDataStoreObserveQueryOperation(modelType: modelType,
                                                          modelSchema: modelSchema,
                                                          predicate: predicate,
                                                          sortInput: sortInput,
                                                          storageEngine: storageEngine,
                                                          dataStorePublisher: dataStorePublisher,
                                                          dataStoreConfiguration: dataStoreConfiguration,
                                                          dispatchedModelSyncedEvent: dispatchedModelSyncedEvent)
        operationQueue.addOperation(operation)
        return operation.publisher
    }
}
