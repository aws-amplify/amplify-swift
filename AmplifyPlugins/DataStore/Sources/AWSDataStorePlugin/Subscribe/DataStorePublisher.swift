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

struct ObserveRequest: AmplifyOperationRequest {
    typealias Options = [AnyHashable: Any]
    var options: [AnyHashable : Any]
    init(options: [AnyHashable: Any] = [:]) {
        self.options = options
    }
}

class ObserveTaskRunner: InternalTaskRunner, InternalTaskAsyncThrowingSequence, InternalTaskThrowingChannel {
    var request: ObserveRequest

    typealias Request = ObserveRequest
    typealias InProcess = MutationEvent

    var publisher: AnyPublisher<MutationEvent, DataStoreError>
    var sink: AnyCancellable?
    
    var context = InternalTaskAsyncThrowingSequenceContext<MutationEvent>()
    private var running = false
    
    public init(request: ObserveRequest = .init(), publisher: AnyPublisher<MutationEvent, DataStoreError>) {
        self.request = request
        self.publisher = publisher
    }
    
    func run() async throws {
        guard !running else { return }
        
        self.sink = publisher.sink { completion in
            switch completion {
            case .finished:
                self.finish()
            case .failure(let error):
                self.fail(error)
            }
        } receiveValue: { mutationEvent in
            
            self.send(mutationEvent)
        }

    }
    
    
}
