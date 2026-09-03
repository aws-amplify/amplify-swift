//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

// `@unchecked Sendable` because the category plugin protocols now require `Sendable` (see
// `Plugin`), and a `Sendable` class may not inherit from a non-`NSObject` superclass. These are
// test doubles driven from a single test at a time.
class MockDataStoreCategoryPlugin: MessageReporter, DataStoreCategoryPlugin, @unchecked Sendable {

    var responders = [ResponderKeys: Any]()

    var key: String {
        return "MockDataStoreCategoryPlugin"
    }

    func configure(using configuration: Any?) throws {
        notify()
    }

    func reset() {
        notify("reset")
    }

    func save<M: Model>(
        _ model: M,
        where condition: QueryPredicate? = nil,
        completion: @escaping @Sendable (DataStoreResult<M>) -> Void
    ) {
        notify("save")

        if let responder = responders[.saveModelListener] as? SaveModelResponder<M> {
            Task {
                if let callback = responder.callback((
                    model: model,
                    where: condition
                )) {
                    completion(callback)
                }
            }
        }
    }

    func save<M: Model>(
        _ model: M,
        where condition: QueryPredicate? = nil
    ) async throws -> M {
        notify("save")
        return model
    }

    func query<M: Model>(
        _ modelType: M.Type,
        byId id: String,
        completion: @escaping @Sendable (DataStoreResult<M?>) -> Void
    ) {
        notify("queryById")

        if let responder = responders[.queryByIdListener] as? QueryByIdResponder<M> {
            Task {
                if let callback = responder.callback((modelType: modelType, id: id)) {
                    completion(callback)
                }
            }
        }
    }

    func query<M: Model>(
        _ modelType: M.Type,
        byId id: String
    ) async throws -> M? {
        notify("queryById")
        return nil
    }

    func query<M: Model>(
        _ modelType: M.Type,
        byIdentifier id: String,
        completion: @escaping @Sendable (DataStoreResult<M?>) -> Void
    ) where M: ModelIdentifiable,
                                                                          M.IdentifierFormat == ModelIdentifierFormat.Default {
        notify("queryByIdentifier")

        if let responder = responders[.queryByIdListener] as? QueryByIdResponder<M> {
            Task {
                if let callback = responder.callback((modelType: modelType, id: id)) {
                    completion(callback)
                }
            }
        }
    }

    func query<M: Model>(
        _ modelType: M.Type,
        byIdentifier id: String
    ) async throws -> M? where M: ModelIdentifiable,
        M.IdentifierFormat == ModelIdentifierFormat.Default {
            notify("queryByIdentifier")
            return nil
    }

    func query<M: Model>(
        _ modelType: M.Type,
        where predicate: QueryPredicate?,
        sort sortInput: QuerySortInput?,
        paginate paginationInput: QueryPaginationInput?,
        completion: @escaping @Sendable (DataStoreResult<[M]>) -> Void
    ) {
        notify("queryByPredicate")

        if let responder = responders[.queryModelsListener] as? QueryModelsResponder<M> {
            Task {
                if let result = responder.callback((
                    modelType: modelType,
                    where: predicate,
                    sort: sortInput,
                    paginate: paginationInput
                )) {
                    completion(result)
                }
            }
        }
    }

    func query<M: Model>(
        _ modelType: M.Type,
        where predicate: QueryPredicate?,
        sort sortInput: QuerySortInput?,
        paginate paginationInput: QueryPaginationInput?
    ) async throws -> [M] {
        notify("queryByPredicate")

        if let responder = responders[.queryModelsListener] as? QueryModelsResponder<M> {
            if let result = responder.callback((
                modelType: modelType,
                where: predicate,
                sort: sortInput,
                paginate: paginationInput
            )) {
                switch result {
                case .success(let models):
                    return models
                case .failure(let error):
                    throw error
                }
            }
        }

        return []
    }

    func query<M>(
        _ modelType: M.Type,
        byIdentifier id: ModelIdentifier<M, M.IdentifierFormat>,
        completion: @escaping @Sendable (DataStoreResult<M?>) -> Void
    ) where M: Model, M: ModelIdentifiable {
        notify("queryWithIdentifier")

       // Hoisted so the task captures a `String` rather than the identifier value.
       let identifierValue = id.stringValue
       if let responder = responders[.queryByIdListener] as? QueryByIdResponder<M> {
           Task {
               if let callback = responder.callback((modelType: modelType, id: identifierValue)) {
                   completion(callback)
               }
           }
       }
    }

    func query<M>(
        _ modelType: M.Type,
        byIdentifier id: ModelIdentifier<M, M.IdentifierFormat>
    ) async throws -> M?
        where M: Model, M: ModelIdentifiable {
            notify("queryWithIdentifier")
            return nil
    }

    func delete<M: Model>(
        _ modelType: M.Type,
        withId id: String,
        where predicate: QueryPredicate? = nil,
        completion: @escaping @Sendable (DataStoreResult<Void>) -> Void
    ) {
        notify("deleteById")

        if let responder = responders[.deleteByIdListener] as? DeleteByIdResponder<M> {
            Task {
                if let callback = responder.callback((modelType: modelType, id: id)) {
                    completion(callback)
                }
            }
        }
    }

    func delete(
        _ modelType: (some Model).Type,
        withId id: String,
        where predicate: QueryPredicate? = nil
    ) async throws {
        notify("deleteById")
    }

    func delete<M: Model>(
        _ modelType: M.Type,
        withIdentifier id: String,
        where predicate: QueryPredicate? = nil,
        completion: @escaping @Sendable (DataStoreResult<Void>) -> Void
    ) where M: ModelIdentifiable,
                                                                             M.IdentifierFormat == ModelIdentifierFormat.Default {
        notify("deleteByIdentifier")

        if let responder = responders[.deleteByIdListener] as? DeleteByIdResponder<M> {
            Task {
                if let callback = responder.callback((modelType: modelType, id: id)) {
                    completion(callback)
                }
            }
        }
    }

    func delete<M: Model>(
        _ modelType: M.Type,
        withIdentifier id: String,
        where predicate: QueryPredicate? = nil
    ) async throws
        where M: ModelIdentifiable, M.IdentifierFormat == ModelIdentifierFormat.Default {
            notify("deleteByIdentifier")
    }

    func delete<M>(
        _ modelType: M.Type,
        withIdentifier id: ModelIdentifier<M, M.IdentifierFormat>,
        where predicate: QueryPredicate?,
        completion: @escaping DataStoreCallback<Void>
    ) where M: Model, M: ModelIdentifiable {
        notify("deleteByIdentifier")

        // Hoisted so the task captures a `String` rather than the identifier value.
        let identifierValue = id.stringValue
        if let responder = responders[.deleteByIdListener] as? DeleteByIdResponder<M> {
            Task {
                if let callback = responder.callback((modelType: modelType, id: identifierValue)) {
                    completion(callback)
                }
            }
        }
    }

    func delete<M>(
        _ modelType: M.Type,
        withIdentifier id: ModelIdentifier<M, M.IdentifierFormat>,
        where predicate: QueryPredicate?
    ) async throws where M: Model, M: ModelIdentifiable {
        notify("deleteByIdentifier")
    }

    func delete<M: Model>(
        _ modelType: M.Type,
        where predicate: QueryPredicate,
        completion: @escaping @Sendable (DataStoreResult<Void>) -> Void
    ) {
        notify("deleteModelTypeByPredicate")

        if let responder = responders[.deleteModelTypeListener] as? DeleteModelTypeResponder<M> {
            Task {
                if let callback = responder.callback((modelType: modelType, where: predicate)) {
                    completion(callback)
                }
            }
        }
    }

    func delete(
        _ modelType: (some Model).Type,
        where predicate: QueryPredicate
    ) async throws {
        notify("deleteModelTypeByPredicate")
    }

    func delete<M: Model>(
        _ model: M,
        where predicate: QueryPredicate? = nil,
        completion: @escaping DataStoreCallback<Void>
    ) {
        notify("deleteByPredicate")

        if let responder = responders[.deleteModelListener] as? DeleteModelResponder<M> {
            Task {
                if let callback = responder.callback((
                    model: model,
                    where: predicate
                )) {
                    completion(callback)
                }
            }
        }
    }

    func delete(
        _ model: some Model,
        where predicate: QueryPredicate? = nil
    ) async throws {
        notify("deleteByPredicate")
    }

    func clear(completion: @escaping DataStoreCallback<Void>) {
        notify("clear")

        if let responder = responders[.clearListener] as? ClearResponder {
            Task {
                if let callback = responder.callback(()) {
                    completion(callback)
                }
            }
        }
    }

    func clear() async throws {
        notify("clear")
    }

    func start(completion: @escaping DataStoreCallback<Void>) {
        notify("start")

        if let responder = responders[.clearListener] as? ClearResponder {
            Task {
                if let callback = responder.callback(()) {
                    completion(callback)
                }
            }
        }
    }

    func start() async throws {
        notify("start")
    }

    func stop(completion: @escaping DataStoreCallback<Void>) {
        notify("stop")

        if let responder = responders[.stopListener] as? StopResponder {
            Task {
                if let callback = responder.callback(()) {
                    completion(callback)
                }
            }
        }
    }

    func stop() async throws {
        notify("stop")
    }

    func publisher(for modelType: (some Model).Type)
    -> AnyPublisher<MutationEvent, DataStoreError> {
        let mutationEvent = MutationEvent(
            id: "testevent",
            modelId: "123",
            modelName: modelType.modelName,
            json: "",
            mutationType: .create,
            createdAt: .now()
        )
        notify("publisher")
        return Result.Publisher(mutationEvent).eraseToAnyPublisher()
    }

    func observe(_ modelType: (some Model).Type) -> AmplifyAsyncThrowingSequence<MutationEvent> {
        return AmplifyAsyncThrowingSequence(parent: nil)
    }

    func observeQuery<M: Model>(
        for modelType: M.Type,
        where predicate: QueryPredicate? = nil,
        sort sortInput: QuerySortInput? = nil
    )
    -> AnyPublisher<DataStoreQuerySnapshot<M>, DataStoreError> {
        notify("observeQuery")
        let snapshot = DataStoreQuerySnapshot<M>(items: [], isSynced: false)
        return Result.Publisher(snapshot).eraseToAnyPublisher()
    }

    func observeQuery<M: Model>(
        for modelType: M.Type,
        where predicate: QueryPredicate?,
        sort sortInput: QuerySortInput?
    ) -> AmplifyAsyncThrowingSequence<DataStoreQuerySnapshot<M>> {

        let request = ObserveQueryRequest()
        let taskRunner = MockObserveQueryTaskRunner<M>(request: request)
        return taskRunner.sequence
    }
}

// `@unchecked Sendable`: the protocol it conforms to now requires `Sendable`. Test double.

class MockSecondDataStoreCategoryPlugin: MockDataStoreCategoryPlugin, @unchecked Sendable {
    override var key: String {
        return "MockSecondDataStoreCategoryPlugin"
    }
}


// Mirrors the plugin's `ObserveQueryRequest`: `Options` must be `Sendable`, and options are unused.
final class ObserveQueryRequest: AmplifyOperationRequest, Sendable {
    struct Options: Sendable {
        init() {}
    }

    let options: Options

    init(options: Options = .init()) {
        self.options = options
    }

}

// `@unchecked Sendable`: the protocol it conforms to now requires `Sendable`. Test double.

class MockObserveQueryTaskRunner<M: Model>: InternalTaskRunner, InternalTaskAsyncThrowingSequence, InternalTaskThrowingChannel, @unchecked Sendable {

    typealias Request = ObserveQueryRequest
    typealias InProcess = DataStoreQuerySnapshot<M>
    var request: ObserveQueryRequest
    var context = InternalTaskAsyncThrowingSequenceContext<DataStoreQuerySnapshot<M>>()
    func run() async throws {

    }

    init(request: ObserveQueryRequest) {
        self.request = request
    }

}
