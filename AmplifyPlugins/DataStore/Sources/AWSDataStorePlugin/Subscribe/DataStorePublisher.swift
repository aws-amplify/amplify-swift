//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

struct DataStorePublisher: ModelSubcriptionBehavior {

    private let subject = PassthroughSubject<MutationEvent, DataStoreError>()

    var publisher: AnyPublisher<MutationEvent, DataStoreError> {
        return subject.eraseToAnyPublisher()
    }

    func send(input: MutationEvent) {
        subject.send(input)
    }

    func send(dataStoreError: DataStoreError) {
        subject.send(completion: .failure(dataStoreError))
    }

    func sendFinished() {
        subject.send(completion: .finished)
    }
}

protocol ModelSubcriptionBehavior {

    var publisher: AnyPublisher<MutationEvent, DataStoreError> { get }

    func send(input: MutationEvent)

    func send(dataStoreError: DataStoreError)

    func sendFinished()
}

class DataStoreObserveOperation<M: Model>: AmplifyInProcessReportingOperation<DataStoreObserveRequest<M>, MutationEvent, Void, DataStoreError> { }


struct DataStoreObserveRequest<M: Model>: AmplifyOperationRequest {

    public let modelType: M.Type
    public let options: Options

    public init(modelType: M.Type, options: Options) {
        self.modelType = modelType
        self.options = options
    }
}

extension DataStoreObserveRequest {
    struct Options {
        public let pluginOptions: Any?

        public init(pluginOptions: Any?) {
            self.pluginOptions = pluginOptions
        }
    }
}

class AWSDataStoreObserveOpertion<M: Model>: DataStoreObserveOperation<M>  {

    let publisher: AnyPublisher<MutationEvent, DataStoreError>
    var sink: AnyCancellable?
    init(modelType: M.Type, publisher: AnyPublisher<MutationEvent, DataStoreError>) {
        self.publisher = publisher

        super.init(categoryType: .dataStore,
                   eventName: "DataStore.Observe",
                   request: .init(modelType: modelType,
                                  options: .init(pluginOptions: nil)))

    }

    override public func main() {
        self.sink = self.publisher.sink { completion in
            self.dispatch(result: .successfulVoid)
        } receiveValue: { mutationEvent in
            self.dispatchInProcess(data: mutationEvent)
        }
    }
}
