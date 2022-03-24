//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

class MockDataStoreCategoryPlugin: MessageReporter, DataStoreCategoryPlugin {

    var responders = [ResponderKeys: Any]()

    var key: String {
        return "MockDataStoreCategoryPlugin"
    }

    func configure(using configuration: Any?) throws {
        notify()
    }

    func reset(onComplete: @escaping BasicClosure) {
        notify("reset")
        onComplete()
    }

    func save<M: Model>(_ model: M,
                        where condition: QueryPredicate? = nil,
                        completion: (DataStoreResult<M>) -> Void) {
        notify("save")

        if let responder = responders[.saveModelListener] as? SaveModelResponder<M> {
            if let callback = responder.callback((model: model,
                                                  where: condition)) {
                completion(callback)
            }
        }
    }

    func query<M: Model>(_ modelType: M.Type,
                         byId id: String,
                         completion: (DataStoreResult<M?>) -> Void) {
        notify("queryById")

        if let responder = responders[.queryByIdListener] as? QueryByIdResponder<M> {
            if let callback = responder.callback((modelType: modelType, id: id)) {
                completion(callback)
            }
        }
    }

    func query<M: Model>(_ modelType: M.Type,
                         where predicate: QueryPredicate?,
                         sort sortInput: QuerySortInput?,
                         paginate paginationInput: QueryPaginationInput?,
                         completion: (DataStoreResult<[M]>) -> Void) {
        notify("queryByPredicate")

        if let responder = responders[.queryModelsListener] as? QueryModelsResponder<M> {
            if let callback = responder.callback((modelType: modelType,
                                                  where: predicate,
                                                  sort: sortInput,
                                                  paginate: paginationInput)) {
                completion(callback)
            }
        }
    }

    func delete<M: Model>(_ modelType: M.Type,
                          withId id: String,
                          where predicate: QueryPredicate? = nil,
                          completion: (DataStoreResult<Void>) -> Void) {
        notify("deleteById")

        if let responder = responders[.deleteByIdListener] as? DeleteByIdResponder<M> {
            if let callback = responder.callback((modelType: modelType, id: id)) {
                completion(callback)
            }
        }
    }

    func delete<M: Model>(_ model: M,
                          where predicate: QueryPredicate? = nil,
                          completion: @escaping DataStoreCallback<Void>) {
        notify("deleteByPredicate")

        if let responder = responders[.deleteModelListener] as? DeleteModelResponder<M> {
            if let callback = responder.callback((model: model,
                                                  where: predicate)) {
                completion(callback)
            }
        }
    }

    func clear(completion: @escaping DataStoreCallback<Void>) {
        notify("clear")

        if let responder = responders[.clearListener] as? ClearResponder {
            if let callback = responder.callback(()) {
                completion(callback)
            }
        }
    }

    func start(completion: @escaping DataStoreCallback<Void>) {
        notify("start")

        if let responder = responders[.clearListener] as? ClearResponder {
            if let callback = responder.callback(()) {
                completion(callback)
            }
        }
    }

    func stop(completion: @escaping DataStoreCallback<Void>) {
        notify("stop")

        if let responder = responders[.stopListener] as? StopResponder {
            if let callback = responder.callback(()) {
                completion(callback)
            }
        }
    }

    func publisher<M: Model>(for modelType: M.Type)
    -> AnyPublisher<MutationEvent, DataStoreError> {
        let mutationEvent = MutationEvent(id: "testevent",
                                          modelId: "123",
                                          modelName: modelType.modelName,
                                          json: "",
                                          mutationType: .create,
                                          createdAt: .now())
        notify("publisher")
        return Result.Publisher(mutationEvent).eraseToAnyPublisher()
    }

    public func observeQuery<M: Model>(for modelType: M.Type,
                                       where predicate: QueryPredicate? = nil,
                                       sort sortInput: QuerySortInput? = nil)
    -> AnyPublisher<DataStoreQuerySnapshot<M>, DataStoreError> {
        notify("observeQuery")
        let snapshot = DataStoreQuerySnapshot<M>(items: [], isSynced: false)
        return Result.Publisher(snapshot).eraseToAnyPublisher()
    }
}

class MockSecondDataStoreCategoryPlugin: MockDataStoreCategoryPlugin {
    override var key: String {
        return "MockSecondDataStoreCategoryPlugin"
    }
}
