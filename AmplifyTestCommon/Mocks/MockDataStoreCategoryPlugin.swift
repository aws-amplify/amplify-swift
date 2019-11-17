//
// Copyright 2018-2019 Amazon.com,
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

    func configure(using configuration: Any) throws {
        notify()
    }

    func reset(onComplete: @escaping BasicClosure) {
        notify("reset")
        onComplete()
    }

    func save<M: Model>(_ model: M,
                        completion: (DataStoreResult<M>) -> Void) {
        notify("save")
    }

    func query<M: Model>(_ modelType: M.Type,
                         byId id: String,
                         completion: (DataStoreResult<M?>) -> Void) {
        notify("queryById")
    }

    func query<M: Model>(_ modelType: M.Type,
                         where predicate: QueryPredicateFactory?,
                         completion: (DataStoreResult<[M]>) -> Void) {
        notify("queryByPredicate")
    }

    func delete<M: Model>(_ model: M,
                          completion: (DataStoreResult<Void>) -> Void) {
        notify("deleteByModel")
    }

    func delete<M: Model>(_ modelType: M.Type,
                          withId id: String,
                          completion: (DataStoreResult<Void>) -> Void) {
        notify("deleteById")
    }

    @available(iOS 13.0, *)
    func publisher<M: Model>(for modelType: M.Type)
        -> AnyPublisher<MutationEvent, DataStoreError> {
            let mutationEvent = MutationEvent(id: "testevent",
                                              modelName: modelType.modelName,
                                              data: "",
                                              mutationType: .create,
                                              createdAt: Date())
            notify("publisher")
            return Result.Publisher(mutationEvent).eraseToAnyPublisher()
    }

}

class MockSecondDataStoreCategoryPlugin: MockDataStoreCategoryPlugin {
    override var key: String {
        return "MockSecondDataStoreCategoryPlugin"
    }
}
