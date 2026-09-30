//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

/// - Note: `@unchecked Sendable`: `Options` is `Any`, so the conformance cannot be checked.
/// See `ObserveQueryRequest`: options are unused, so an empty `Sendable` type is used instead of
/// `Any`, which cannot satisfy the `Sendable` requirement on `AmplifyOperationRequest.Options`.
struct ObserveRequest: AmplifyOperationRequest, Sendable {
    struct Options: Sendable {
        init() {}
    }

    let options: Options

    init(options: Options = .init()) {
        self.options = options
    }
}

/// - Note: `final` and `@unchecked Sendable` to satisfy `InternalTaskRunner`'s `Sendable`
///   requirement. `sink` and `context` are established once during `run()` and not mutated
///   concurrently thereafter.
final class ObserveTaskRunner: InternalTaskRunner, InternalTaskAsyncThrowingSequence, InternalTaskThrowingChannel, @unchecked Sendable {
    let request: ObserveRequest

    typealias Request = ObserveRequest
    typealias InProcess = MutationEvent

    var publisher: AnyPublisher<MutationEvent, DataStoreError>
    var sink: AnyCancellable?
    var context = InternalTaskAsyncThrowingSequenceContext<InProcess>()

    private var running = false

    init(request: ObserveRequest = .init(), publisher: AnyPublisher<MutationEvent, DataStoreError>) {
        self.request = request
        self.publisher = publisher
    }

    func run() async throws {
        guard !running else { return }
        running = true

        sink = publisher.sink { completion in
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
