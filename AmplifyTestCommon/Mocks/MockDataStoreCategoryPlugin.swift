//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

class MockDataStoreCategoryPlugin: MessageReporter, DataStoreCategoryPlugin {

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
    }

    func query<M: Model>(_ modelType: M.Type,
                         byId id: String,
                         completion: (DataStoreResult<M?>) -> Void) {
        notify("queryById")
    }

    func query<M: Model>(_ modelType: M.Type,
                         where predicate: QueryPredicate?,
                         sort sortInput: QuerySortInput?,
                         paginate paginationInput: QueryPaginationInput?,
                         completion: (DataStoreResult<[M]>) -> Void) {
        notify("queryByPredicate")
    }

    func delete<M: Model>(_ modelType: M.Type,
                          withId id: String,
                          completion: (DataStoreResult<Void>) -> Void) {
        notify("deleteById")
    }

    func delete<M: Model>(_ model: M,
                          where predicate: QueryPredicate? = nil,
                          completion: @escaping DataStoreCallback<Void>) {
        notify("deleteByPredicate")
    }

    func clear(completion: @escaping DataStoreCallback<Void>) {
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
