//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import Combine

public typealias DataStorePublisher<Output> = AnyPublisher<Output, DataStoreError>

public extension DataStoreBaseBehavior {
    func clear() -> DataStorePublisher<Void> {
        Future { promise in
            self.clear(completion: { promise($0) })
        }.eraseToAnyPublisher()
    }

    func delete<M: Model>(
        _ modelType: M.Type,
        withId id: String
    ) -> DataStorePublisher<Void> {
        Future { promise in
            self.delete(modelType, withId: id, completion: { result in promise(result) })
        }.eraseToAnyPublisher()
    }

    func delete<M: Model>(
        _ model: M,
        where predicate: QueryPredicate? = nil
    ) -> DataStorePublisher<Void> {
        Future { promise in
            self.delete(model, where: predicate, completion: { result in promise(result) })
        }.eraseToAnyPublisher()
    }

    func query<M: Model>(
        _ modelType: M.Type,
        byId id: String
    ) -> DataStorePublisher<M?> {
        Future { promise in
            self.query(modelType, byId: id, completion: { result in promise(result) })
        }.eraseToAnyPublisher()
    }

    func query<M: Model>(
        _ modelType: M.Type,
        where predicate: QueryPredicate? = nil,
        paginate paginationInput: QueryPaginationInput? = nil
    ) -> DataStorePublisher<[M]> {
        Future { promise in
            self.query(
                modelType,
                where: predicate,
                paginate: paginationInput,
                completion: { result in
                    promise(result)
            })
        }.eraseToAnyPublisher()
    }

    func save<M: Model>(
        _ model: M,
        where condition: QueryPredicate? = nil
    ) -> DataStorePublisher<M> {
        Future { promise in
            self.save(model, where: condition, completion: { result in
                promise(result)
            })
        }.eraseToAnyPublisher()
    }

}
