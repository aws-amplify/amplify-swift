//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine
import Foundation

@available(iOS 13.0, *)
final class OutgoingMutationQueue {

    private let stateMachine: StateMachine<State, Action>
    private var stateMachineSink: AnyCancellable?

    private let operationQueue: OperationQueue

    private let workQueue = DispatchQueue(label: "com.amazonaws.OutgoingMutationOperationQueue",
                                          target: DispatchQueue.global())

    private weak var api: APICategoryGraphQLBehavior?
    private var subscription: Subscription?

    init() {
        let operationQueue = OperationQueue()
        operationQueue.name = "com.amazonaws.OutgoingMutationOperationQueue"
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.isSuspended = true

        self.operationQueue = operationQueue

        self.stateMachine = StateMachine(initialState: .notInitialized,
                                         resolver: OutgoingMutationQueue.Resolver.resolve(currentState:action:))

        self.stateMachineSink = stateMachine
            .$state
            .sink { [weak self] newState in
                guard let self = self else {
                    return
                }
                self.log.verbose("New state: \(newState)")
                self.workQueue.async {
                    self.respond(to: newState)
                }
        }

        stateMachine.notify(action: .initialized)
    }

    // MARK: - Public API

    func startSyncingToCloud(api: APICategoryGraphQLBehavior, mutationEventPublisher: MutationEventPublisher) {
        stateMachine.notify(action: .receivedStart(api, mutationEventPublisher))
    }

    func cancel() {
        // Techncially this should be in a "cancelling" responder, but it's simpler to cancel here and move straight
        // to .finished. If in the future we need to add more work to the teardown state, move it to a separate method.
        operationQueue.cancelAllOperations()
        stateMachine.notify(action: .receivedCancel)
    }

    func pauseSyncingToCloud() {
        operationQueue.isSuspended = true
    }

    // MARK: - Responders

    /// Listens to incoming state changes and invokes the appropriate asynchronous methods in response.
    private func respond(to newState: State) {
        log.verbose("\(#function): \(newState)")

        switch newState {

        case .starting(let api, let mutationEventPublisher):
            start(api: api, mutationEventPublisher: mutationEventPublisher)

        case .requestingEvent:
            requestEvent()

        case .enqueuingEvent(let mutationEvent):
            enqueue(mutationEvent: mutationEvent)

        case .inError(let error):
            // Maybe we have to notify the Hub?
            log.error(error: error)

        case .notInitialized,
             .notStarted,
             .waitingForSubscription,
             .waitingForEvent,
             .finished:
            break
        }

    }

    /// Responder method for `starting`. Starts the operation queue and subscribes to the publisher. Return actions:
    /// - started
    private func start(api: APICategoryGraphQLBehavior, mutationEventPublisher: MutationEventPublisher) {
        self.api = api
        operationQueue.isSuspended = false
        mutationEventPublisher.publisher.subscribe(self)
        stateMachine.notify(action: .started)
    }

    /// Responder method for `enqueue`. Notify actions:
    /// - errored
    /// - enqueued
    private func enqueue(mutationEvent: MutationEvent) {
        guard let api = api else {
            let dataStoreError = DataStoreError.configuration(
                "API is unexpectedly nil",
                """
                The reference to storageAdapter has been released while an ongoing mutation was being processed.
                There is a possibility that there is a bug if this error persists. Please take a look at
                https://github.com/aws-amplify/amplify-ios/issues to see if there are any existing issues that
                match your scenario, and file an issue with the details of the bug if there isn't.
                """
            )
            stateMachine.notify(action: .errored(dataStoreError))
            return
        }

        let syncMutationToCloudOperation =
            SyncMutationToCloudOperation(mutationEvent: mutationEvent, api: api)

        operationQueue.addOperation(syncMutationToCloudOperation)
        stateMachine.notify(action: .enqueuedEvent(mutationEvent))
    }

    /// Responder method for `requestingEvent`. Requests the next event from the mutation event publisher.
    /// Notify actions:
    /// - errored
    /// - requestedEvent
    private func requestEvent() {
        subscription?.request(.max(1))
        stateMachine.notify(action: .requestedEvent)
    }
}

extension OutgoingMutationQueue: Subscriber {
    typealias Input = MutationEvent
    typealias Failure = DataStoreError

    func receive(subscription: Subscription) {
        // Technically, saving the subscription should probably be done in a separate method, but it seems overkill
        // for a lightweight operation.
        self.subscription = subscription
        stateMachine.notify(action: .receivedSubscription)
    }

    func receive(_ mutationEvent: MutationEvent) -> Subscribers.Demand {
        stateMachine.notify(action: .receivedEvent(mutationEvent))
        return .none
    }

    // TODO: Resolve with an appropriate state machine notification
    func receive(completion: Subscribers.Completion<DataStoreError>) {
        subscription?.cancel()
    }
}

extension OutgoingMutationQueue: DefaultLogger { }
