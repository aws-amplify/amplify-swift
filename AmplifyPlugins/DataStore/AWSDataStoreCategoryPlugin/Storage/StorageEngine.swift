//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation

public typealias ModelSubscription<M: Model> = AnySubscriber<M, DataStoreError>

// TODO we might need to define `AnyModel` so we can have some type easure
public typealias ModelSubject<M: Model> = PassthroughSubject<M, DataStoreError>

final public class StorageEngine: StorageEngineBehavior {

    let adapter: StorageEngineAdapter

    public init(adapter: StorageEngineAdapter) {
        self.adapter = adapter
    }

    convenience init() throws {
        let key = kCFBundleNameKey as String
        let databaseName = Bundle.main.object(forInfoDictionaryKey: key) as? String
        try self.init(adapter: SQLiteStorageEngineAdapter(databaseName: databaseName ?? "app"))
    }

    public func setUp(models: [Model.Type]) throws {
        models.forEach(registerModel(type:))
        try adapter.setUp(models: models)
    }

    public func save<M: Model>(_ model: M, completion: DataStoreCallback<M>) {
        let modelType = type(of: model)
        adapter.save(model) {
            switch $0 {
            case .result:
                do {
                    let event = try MutationEvent.from(model: model,
                                                       type: .save,
                                                       source: .storageEngine)
                    // TODO update the mutation queue (sync engine)
                    // define the responsability of each layer
                } catch {
                    completion(.failure(causedBy: error))
                }
            case .error(let error):
                completion(.error(error))
            }
        }
    }

    public func delete<M: Model>(_ modelType: M.Type,
                                 withId id: Identifier,
                                 completion: DataStoreCallback<Void>) {
        adapter.delete(modelType, withId: id, completion: completion)
    }

    public func query<M: Model>(_ modelType: M.Type,
                                predicate: QueryPredicate? = nil,
                                completion: DataStoreCallback<[M]>) {
        return adapter.query(modelType, predicate: predicate, completion: completion)
    }

    public func subscribe<M: Model>(_ modelType: M.Type) -> ModelSubscription<M> {
        fatalError("subscribe not implemented yet")
    }

}
