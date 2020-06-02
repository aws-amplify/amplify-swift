//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

class MockDataStoreCategoryPlugin: MessageReporter, DataStoreCategoryPlugin {
    struct Responders {
        var clear: ClearResponder?
        var deleteById: DeleteByIdResponder?
        var deleteByInstance: DeleteByInstanceResponder?
        var queryById: QueryByIdResponder?
        var queryByPredicate: QueryByPredicateResponder?
        var save: SaveResponder?
    }

    var responders: Responders

    override init() {
        self.responders = Responders()
        super.init()
    }

    var key: String {
        return "MockDataStoreCategoryPlugin"
    }

    func configure(using configuration: Any) throws {
        notify()
    }

    func reset(onComplete: @escaping BasicClosure) {
        notify("reset")
        onComplete()
    }

    func save<M: Model>(_ model: M,
                        where condition: QueryPredicate? = nil,
                        completion: (DataStoreResult<M>) -> Void) {
        if let responder = responders.save {
            let result = responder(model, condition)
            switch result {
            case .failure(let dataStoreError):
                completion(.failure(dataStoreError))
            case .success(let someModel):
                if let concreteModel = someModel as? M {
                    completion(.success(concreteModel))
                }
            }
        }

        notify("save")
    }

    func query<M: Model>(_ modelType: M.Type,
                         byId id: String,
                         completion: (DataStoreResult<M?>) -> Void) {
        if let responder = responders.queryById {
            let result = responder(modelType, id)
            switch result {
            case .failure(let dataStoreError):
                completion(.failure(dataStoreError))
            case .success(let someModel):
                if let concreteModel = someModel as? M {
                    completion(.success(concreteModel))
                }
            }
        }
        notify("queryById")
    }

    func query<M: Model>(_ modelType: M.Type,
                         where predicate: QueryPredicate?,
                         paginate paginationInput: QueryPaginationInput?,
                         completion: (DataStoreResult<[M]>) -> Void) {
        if let responder = responders.queryByPredicate {
            let result = responder(modelType, predicate, paginationInput)
            switch result {
            case .failure(let dataStoreError):
                completion(.failure(dataStoreError))
            case .success(let someModel):
                if let models = someModel as? [M] {
                    completion(.success(models))
                }
            }
        }
        notify("queryByPredicate")
    }

    func delete<M: Model>(_ modelType: M.Type,
                          withId id: String,
                          completion: (DataStoreResult<Void>) -> Void) {
        if let responder = responders.deleteById {
            let result = responder(modelType, id)
            completion(result)
        }
        notify("deleteById")
    }

    func delete<M: Model>(_ model: M,
                          where predicate: QueryPredicate? = nil,
                          completion: @escaping DataStoreCallback<Void>) {
        if let responder = responders.deleteByInstance {
            let result = responder(model, predicate)
            completion(result)
        }
        notify("deleteByPredicate")
    }

    func clear(completion: @escaping DataStoreCallback<Void>) {
        if let responder = responders.clear {
            let result = responder()
            completion(result)
        }
        notify("clear")
    }

    @available(iOS 13.0, *)
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

}

class MockSecondDataStoreCategoryPlugin: MockDataStoreCategoryPlugin {
    override var key: String {
        return "MockSecondDataStoreCategoryPlugin"
    }
}
