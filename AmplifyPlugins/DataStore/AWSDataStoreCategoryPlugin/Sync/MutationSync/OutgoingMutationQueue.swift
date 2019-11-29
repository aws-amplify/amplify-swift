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

        log.verbose("Initialized")
        stateMachine.notify(action: .initialized)
    }

    // MARK: - Public API

    func startSyncingToCloud(api: APICategoryGraphQLBehavior, mutationEventPublisher: MutationEventPublisher) {
        log.verbose(#function)
        stateMachine.notify(action: .receivedStart(api, mutationEventPublisher))
    }

    func cancel() {
        log.verbose(#function)
        // Techncially this should be in a "cancelling" responder, but it's simpler to cancel here and move straight
        // to .finished. If in the future we need to add more work to the teardown state, move it to a separate method.
        operationQueue.cancelAllOperations()
        stateMachine.notify(action: .receivedCancel)
    }

    func pauseSyncingToCloud() {
        log.verbose(#function)
        operationQueue.isSuspended = true
    }

    // MARK: - Responders

    /// Listens to incoming state changes and invokes the appropriate asynchronous methods in response.
    private func respond(to newState: State) {
        log.verbose("\(#function): \(newState)")

        switch newState {

        case .starting(let api, let mutationEventPublisher):
            start(api: api, mutationEventPublisher: mutationEventPublisher)

        case .processingEvents:
            startProcessingEvents()

        case .inError(let error):
            // Maybe we have to notify the Hub?
            log.error(error: error)

        case .notInitialized,
             .notStarted,
             .finished:
            break
        }

    }

    /// Responder method for `starting`. Starts the operation queue and subscribes to the publisher. Return actions:
    /// - started
    private func start(api: APICategoryGraphQLBehavior, mutationEventPublisher: MutationEventPublisher) {
        log.verbose(#function)
        self.api = api
        operationQueue.isSuspended = false

        // State machine notification to ".receivedSubscription" will be handled in `receive(subscription:)`
        mutationEventPublisher.publisher.subscribe(self)
    }

    /// Responder method for `processingEvents`. Requests the next event from the mutation event publisher.
    /// Notify actions:
    /// - errored
    /// - requestedEvent
    private func startProcessingEvents() {
        requestEvent()
    }

    // MARK: - Event loop processing

    private func requestEvent() {
        log.verbose(#function)
        guard let subscription = subscription else {
            let dataStoreError = DataStoreError.unknown(
                "No subscription when requesting event",
                """
                The outgoing mutation queue attempted to request event without an active subscription.
                \(AmplifyErrorMessages.reportBugToAWS())
                """
            )
            stateMachine.notify(action: .errored(dataStoreError))
            return
        }
        subscription.request(.max(1))
    }

    private func enqueue(_ mutationEvent: MutationEvent) {
        log.verbose(#function)
        guard let api = api else {
            let dataStoreError = DataStoreError.configuration(
                "API is unexpectedly nil",
                """
                The reference to storageAdapter has been released while an ongoing mutation was being processed.
                \(AmplifyErrorMessages.reportBugToAWS())
                """
            )
            stateMachine.notify(action: .errored(dataStoreError))
            return
        }

        let syncMutationToCloudOperation =
            SyncMutationToCloudOperation(mutationEvent: mutationEvent, api: api)

        operationQueue.addOperation(syncMutationToCloudOperation)
        requestEvent()
    }

}

@available(iOS 13.0, *)
extension OutgoingMutationQueue: Subscriber {
    typealias Input = MutationEvent
    typealias Failure = Never

    func receive(subscription: Subscription) {
        log.verbose(#function)
        // Technically, saving the subscription should probably be done in a separate method, but it seems overkill
        // for a lightweight operation.
        self.subscription = subscription
        stateMachine.notify(action: .receivedSubscription)
    }

    func receive(_ mutationEvent: MutationEvent) -> Subscribers.Demand {
        log.verbose(#function)
        enqueue(mutationEvent)
        return .none
    }

    // TODO: Resolve with an appropriate state machine notification
    func receive(completion: Subscribers.Completion<Never>) {
        log.verbose(#function)
        subscription?.cancel()
    }
}

@available(iOS 13.0, *)
extension OutgoingMutationQueue: DefaultLogger { }
