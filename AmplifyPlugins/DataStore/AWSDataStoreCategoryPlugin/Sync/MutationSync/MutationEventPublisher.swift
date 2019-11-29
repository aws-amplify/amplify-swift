//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

/// Publishes mutation events to downstream subscribers for subsequent sync to the API.
protocol MutationEventPublisher: class {
    var publisher: AnyPublisher<MutationEvent, Never> { get }
}

protocol MutationEventSubject: class {
    func publish(mutationEvent: MutationEvent)
}

/// Publishes incoming mutation events so downstream subscribers can deliver them to a cloud API
///
/// Internally, this class buffers incoming events until a subscription request is received. At that time, a publisher
/// is created that
final class AWSMutationEventPublisher: MutationEventPublisher, MutationEventSubject {

    private enum IncomingEventDestination {
        case buffer
        case subject
    }

    /// Synchronizes submitting events and creating the publisher
    private let workQueue = DispatchQueue(label: "com.amazonaws.AWSMutationEventPublisher",
                                          target: DispatchQueue.global())

    /// Routes incoming events to the appropriate receiver
    private var incomingEventDestination: IncomingEventDestination

    /// Events received prior to a downstream subscription request are buffered in this array
    private var eventBuffer: [MutationEvent]

    /// Events received after the subscription are passed through to this subject
    private let subject: PassthroughSubject<MutationEvent, Never>

    /// Lazily inits a `Deferred` publisher which loads mutation events from the database and delivers them, prior to
    /// delivering new events via a passthrough subject.
    private var _publisher: AnyPublisher<MutationEvent, Never>?
    var publisher: AnyPublisher<MutationEvent, Never> {
        workQueue.sync {
            if let publisher = _publisher {
                return publisher
            }

            log.verbose("Creating publisher")
            let publisher = Deferred {
                self.workQueue.sync {
                    self.createPublisher()
                }
            }.eraseToAnyPublisher()
            _publisher = publisher
            return publisher
        }
    }

    init() {
        self.eventBuffer = [MutationEvent]()
        self.subject = PassthroughSubject<MutationEvent, Never>()
        self.incomingEventDestination = .buffer
        log.verbose("Initialized")
    }

    /// Publishes a mutationEvent to the PassthroughSubject. If there are no subscribers, this event is silently
    /// dropped, but since it has already been saved to disk, it will be handled whenever the OutgoingMutationQueue
    /// subscribes to us.
    ///
    /// Internally, this method blocks on `workQueue` to ensure synchronization the subscription request and the
    /// changeover from buffered events to a passthrough subject
    func publish(mutationEvent: MutationEvent) {
        workQueue.sync {
            switch incomingEventDestination {
            case .buffer:
                log.verbose("Buffering: \(mutationEvent)")
                eventBuffer.append(mutationEvent)
            case .subject:
                log.verbose("Passing through to subject: \(mutationEvent)")
                subject.send(mutationEvent)
            }
        }
    }

    /// This method must be invoked from the `workQueue`, exactly once, when the publisher is first created.
    private func createPublisher() -> AnyPublisher<MutationEvent, Never> {
        log.verbose("Creating publisher with \(eventBuffer.count) buffered events")
        let eventBufferSequence = Publishers.Sequence<[MutationEvent], Never>(sequence: eventBuffer)
        let publisher = Publishers.Concatenate(prefix: eventBufferSequence, suffix: subject)
            .eraseToAnyPublisher()
        incomingEventDestination = .subject
        return publisher
    }

    func reset(onComplete: () -> Void) {
        subject.send(completion: .finished)
        onComplete()
    }
}

extension AWSMutationEventPublisher: DefaultLogger { }
