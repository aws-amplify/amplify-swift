//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

/// An initial sync that finishes only when the test says so
final class HeldInitialSyncOrchestrator: InitialSyncOrchestrator, @unchecked Sendable {
    typealias Completion = @Sendable (Result<Void, DataStoreError>) -> Void

    static let factory: InitialSyncOrchestratorFactory = { _, _, _, _, _ in HeldInitialSyncOrchestrator() }
    /// Completions of every sync started, oldest first
    static let completions = AtomicValue<[Completion]>(initialValue: [])
    /// Called after each sync starts, with how many have started
    static let onSync = AtomicValue<(@Sendable (Int) -> Void)?>(initialValue: nil)
    static let cancellations = AtomicValue(initialValue: 0)

    private let subject = PassthroughSubject<InitialSyncOperationEvent, DataStoreError>()
    var publisher: AnyPublisher<InitialSyncOperationEvent, DataStoreError> { subject.eraseToAnyPublisher() }

    static func reset() {
        completions.set([])
        onSync.set(nil)
        cancellations.set(0)
    }

    func sync(completion: @escaping Completion) {
        var count = 0
        Self.completions.with { completions in
            completions.append(completion)
            count = completions.count
        }
        Self.onSync.get()?(count)
    }

    func cancel() {
        _ = Self.cancellations.increment()
    }
}

/// A reconciliation queue whose subscriptions fail as soon as they are activated
final class FailingOnStartReconciliationQueue: MockAWSIncomingEventReconciliationQueue, @unchecked Sendable {
    override func start() {
        incomingEventSubject.send(completion: .failure(
            DataStoreError.api(APIError.networkError("lost", nil, URLError(.networkConnectionLost)))
        ))
    }
}

// `@unchecked Sendable`: `XCTestCase` is not `Sendable`, but the test body is captured by the
// `@Sendable` closures the API now takes. XCTest runs one test at a time.
class RemoteSyncEngineStartupTests: XCTestCase, @unchecked Sendable {
    var apiPlugin: MockAPICategoryPlugin!
    var storageAdapter: StorageEngineAdapter!
    var retryPolicy: MockRequestRetryablePolicy!
    /// The reconciliation queue of each startup, oldest first
    let queues = AtomicValue<[MockAWSIncomingEventReconciliationQueue]>(initialValue: [])

    private static let networkFailure = DataStoreError.api(
        APIError.networkError("lost", nil, URLError(.networkConnectionLost))
    )

    override func setUp() {
        super.setUp()
        apiPlugin = MockAPICategoryPlugin()
        storageAdapter = MockSQLiteStorageEngineAdapter()
        retryPolicy = MockRequestRetryablePolicy()
        queues.set([])
        HeldInitialSyncOrchestrator.reset()
        MockAWSInitialSyncOrchestrator.reset()
    }

    override func tearDown() {
        HeldInitialSyncOrchestrator.reset()
        apiPlugin = nil
        storageAdapter = nil
        retryPolicy = nil
        super.tearDown()
    }

    /// Creates each startup's reconciliation queue, which reports its subscriptions connected after 50 ms if asked to
    private func reconciliationQueueFactory(
        connectingSubscriptions: Bool,
        failingOnStart: Bool
    ) -> IncomingEventReconciliationQueueFactory {
        let queues = queues
        return { modelSchemas, api, storageAdapter, syncExpressions, auth, _, _, _ in
            let queue: MockAWSIncomingEventReconciliationQueue = failingOnStart
                ? FailingOnStartReconciliationQueue(
                    modelSchemas: modelSchemas,
                    api: api,
                    storageAdapter: storageAdapter,
                    syncExpressions: syncExpressions,
                    auth: auth
                )
                : MockAWSIncomingEventReconciliationQueue(
                    modelSchemas: modelSchemas,
                    api: api,
                    storageAdapter: storageAdapter,
                    syncExpressions: syncExpressions,
                    auth: auth
                )
            queues.with { $0.append(queue) }
            if connectingSubscriptions {
                DispatchQueue.global().asyncAfter(deadline: .now() + .milliseconds(50)) {
                    queue.incomingEventSubject.send(.initialized)
                }
            }
            return queue
        }
    }

    private func makeEngine(
        initialSyncOrchestratorFactory: @escaping InitialSyncOrchestratorFactory = HeldInitialSyncOrchestrator.factory,
        connectingSubscriptions: Bool = true,
        failingOnStart: Bool = false,
        subscriptionSetupTimeout: TimeInterval = RemoteSyncEngine.defaultSubscriptionSetupTimeout
    ) throws -> RemoteSyncEngine {
        try RemoteSyncEngine(
            storageAdapter: storageAdapter,
            dataStoreConfiguration: .testDefault(),
            outgoingMutationQueue: MockOutgoingMutationQueue(),
            initialSyncOrchestratorFactory: initialSyncOrchestratorFactory,
            reconciliationQueueFactory: reconciliationQueueFactory(
                connectingSubscriptions: connectingSubscriptions,
                failingOnStart: failingOnStart
            ),
            requestRetryablePolicy: retryPolicy,
            subscriptionSetupTimeout: subscriptionSetupTimeout
        )
    }

    /// Fails the subscriptions of the newest startup
    private func failNewestSubscriptions() {
        queues.get().last?.incomingEventSubject.send(completion: .failure(Self.networkFailure))
    }

    private func waitUntil(_ condition: () -> Bool, timeout: TimeInterval = 2) {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            Thread.sleep(forTimeInterval: 0.02)
        }
    }

    /// Losing subscriptions during initial sync cancels that sync and cleans up for a restart.
    ///
    /// - Given: A starting engine whose initial sync is still running
    /// - When:
    ///    - Its subscriptions fail with a network error
    /// - Then:
    ///    - The engine cancels the initial sync, cleans up, and asks the retry policy about that error,
    ///      instead of waiting forever
    ///
    func testSubscriptionFailureDuringInitialSync_cancelsItAndCleansUpForARestart() throws {
        let retryErrorCode = AtomicValue<URLError.Code?>(initialValue: nil)
        retryPolicy.setOnRetryRequestAdvice { urlError, _, _ in
            retryErrorCode.set(urlError?.code)
        }
        HeldInitialSyncOrchestrator.onSync.set { [weak self] _ in
            self?.failNewestSubscriptions()
        }
        let engine = try makeEngine()
        let cleanedUp = expectation(description: "The engine cleans up")
        let sink = engine.publisher.sink(receiveCompletion: { _ in }, receiveValue: { event in
            if case .cleanedUp = event {
                cleanedUp.fulfill()
            }
        })

        engine.start(api: apiPlugin, auth: nil)

        wait(for: [cleanedUp], timeout: 3)
        waitUntil { retryErrorCode.get() != nil }
        XCTAssertEqual(retryErrorCode.get(), .networkConnectionLost)
        XCTAssertEqual(HeldInitialSyncOrchestrator.cancellations.get(), 1)
        sink.cancel()
    }

    /// An initial sync from an earlier startup can't finish a restarted one.
    ///
    /// - Given: An engine that restarted after losing subscriptions during its first initial sync
    /// - When:
    ///    - The restarted startup is in its own initial sync
    ///    - Then the first initial sync finishes
    /// - Then:
    ///    - The engine keeps waiting for its own initial sync, and finishes when that one does
    ///
    func testInitialSyncFromAnEarlierStartup_doesNotFinishARestartedOne() throws {
        retryPolicy.pushOnRetryRequestAdvice(response: RequestRetryAdvice(shouldRetry: true, retryInterval: .milliseconds(10)))
        let restartedSyncStarted = expectation(description: "The restarted startup starts its own initial sync")
        HeldInitialSyncOrchestrator.onSync.set { [weak self] count in
            if count == 1 {
                self?.failNewestSubscriptions()
            } else {
                restartedSyncStarted.fulfill()
            }
        }
        let engine = try makeEngine()
        let performedInitialSyncs = AtomicValue(initialValue: 0)
        let sink = engine.publisher.sink(receiveCompletion: { _ in }, receiveValue: { event in
            if case .performedInitialSync = event {
                _ = performedInitialSyncs.increment()
            }
        })

        engine.start(api: apiPlugin, auth: nil)
        wait(for: [restartedSyncStarted], timeout: 3)
        let completions = HeldInitialSyncOrchestrator.completions.get()
        guard completions.count == 2 else {
            XCTFail("Expected one initial sync per startup, got \(completions.count)")
            return
        }

        completions[0](.successfulVoid)
        Thread.sleep(forTimeInterval: 0.3)
        XCTAssertEqual(performedInitialSyncs.get(), 0, "The first startup's sync finished the restarted one")

        completions[1](.successfulVoid)
        waitUntil { performedInitialSyncs.get() > 0 }
        XCTAssertEqual(performedInitialSyncs.get(), 1)

        let stopped = expectation(description: "The engine stops")
        engine.stop { _ in stopped.fulfill() }
        wait(for: [stopped], timeout: 3)
        sink.cancel()
    }

    /// Subscriptions that never connect clean up for a restart after the timeout.
    ///
    /// - Given: An engine with a 0.2 s subscription setup timeout
    /// - When:
    ///    - Its subscriptions neither connect nor fail
    /// - Then:
    ///    - The engine cleans up and asks the retry policy about a timeout, which it retries
    ///
    func testSubscriptionsThatNeverConnect_cleanUpForARestartAfterTheTimeout() throws {
        let retryErrorCode = AtomicValue<URLError.Code?>(initialValue: nil)
        retryPolicy.setOnRetryRequestAdvice { urlError, _, _ in
            retryErrorCode.set(urlError?.code)
        }
        let engine = try makeEngine(connectingSubscriptions: false, subscriptionSetupTimeout: 0.2)
        let cleanedUp = expectation(description: "The engine cleans up")
        let sink = engine.publisher.sink(receiveCompletion: { _ in }, receiveValue: { event in
            if case .cleanedUp = event {
                cleanedUp.fulfill()
            }
        })

        engine.start(api: apiPlugin, auth: nil)

        wait(for: [cleanedUp], timeout: 3)
        waitUntil { retryErrorCode.get() != nil }
        XCTAssertEqual(retryErrorCode.get(), .timedOut)
        XCTAssertTrue(
            RequestRetryablePolicy().retryRequestAdvice(urlError: URLError(.timedOut), httpURLResponse: nil, attemptNumber: 1)
                .shouldRetry
        )
        sink.cancel()
    }

    /// Losing subscriptions while they are activated cleans up instead of stalling.
    ///
    /// - Given: A starting engine whose subscriptions fail as soon as they are activated
    /// - When:
    ///    - Startup reaches `.activatingCloudSubscriptions`
    /// - Then:
    ///    - The engine cleans up, instead of waiting for a `.started` that the failed queue never sends
    ///
    func testSubscriptionFailureWhileActivating_cleansUp() throws {
        let engine = try makeEngine(initialSyncOrchestratorFactory: MockAWSInitialSyncOrchestrator.factory, failingOnStart: true)
        let cleanedUp = expectation(description: "The engine cleans up")
        let sink = engine.publisher.sink(receiveCompletion: { _ in }, receiveValue: { event in
            if case .cleanedUp = event {
                cleanedUp.fulfill()
            }
        })

        engine.start(api: apiPlugin, auth: nil)

        wait(for: [cleanedUp], timeout: 3)
        sink.cancel()
    }

    /// Subscriptions that connect in time don't trip the timeout.
    ///
    /// - Given: An engine with a 1 s subscription setup timeout
    /// - When:
    ///    - Its subscriptions connect after 50 ms
    /// - Then:
    ///    - Sync starts, and the engine doesn't clean up once the timeout has passed
    ///
    func testSubscriptionsThatConnectInTime_doNotRestartSync() throws {
        let engine = try makeEngine(
            initialSyncOrchestratorFactory: MockAWSInitialSyncOrchestrator.factory,
            subscriptionSetupTimeout: 1
        )
        let syncStarted = expectation(description: "Sync starts")
        let cleanedUp = expectation(description: "The engine cleans up")
        cleanedUp.isInverted = true
        let sink = engine.publisher.sink(receiveCompletion: { _ in }, receiveValue: { event in
            switch event {
            case .syncStarted:
                syncStarted.fulfill()
            case .cleanedUp:
                cleanedUp.fulfill()
            default:
                break
            }
        })

        engine.start(api: apiPlugin, auth: nil)

        wait(for: [syncStarted], timeout: 3)
        wait(for: [cleanedUp], timeout: 1.5)

        let stopped = expectation(description: "The engine stops")
        engine.stop { _ in stopped.fulfill() }
        wait(for: [stopped], timeout: 3)
        sink.cancel()
    }

    /// A subscription completion that reaches an engine with no subscriptions changes nothing.
    ///
    /// - Given: An engine that hasn't started
    /// - When:
    ///    - Its subscriptions report a failure, then that they finished
    /// - Then:
    ///    - The engine stays `.notStarted` and doesn't republish that state, which would run its work again
    ///
    func testSubscriptionCompletionWithoutSubscriptions_isIgnored() throws {
        let engine = try makeEngine()
        let publications = AtomicValue(initialValue: 0)
        let sink = engine.stateMachine.$state.dropFirst().sink { _ in _ = publications.increment() }

        engine.onReceiveCompletion(receiveCompletion: .failure(Self.networkFailure))
        engine.onReceiveCompletion(receiveCompletion: .finished)

        XCTAssertEqual(engine.stateMachine.state.displayName, "notStarted")
        XCTAssertEqual(publications.get(), 0)
        sink.cancel()
    }

    /// Losing subscriptions ends startup in every state that has them, and leaves the other states alone.
    ///
    /// - Given: A state machine in each RemoteSyncEngine state
    /// - When:
    ///    - Its subscriptions fail
    /// - Then:
    ///    - States with subscriptions move to `.cleaningUp`
    ///    - Other states neither change nor republish, so their work doesn't run twice
    ///
    func testSubscriptionFailure_endsEveryStateWithSubscriptions() throws {
        let error = Self.networkFailure
        let publisher = AWSMutationEventPublisher(eventSource: CapturingMutationEventSource())
        let withSubscriptions: [RemoteSyncEngine.State] = [
            .initializingSubscriptions(apiPlugin, storageAdapter),
            .performingInitialSync,
            .activatingCloudSubscriptions,
            .activatingMutationQueue(apiPlugin, publisher, nil),
            .notifyingSyncStarted,
            .syncEngineActive
        ]
        let withoutSubscriptions: [RemoteSyncEngine.State] = [
            .notStarted,
            .pausingSubscriptions,
            .pausingMutationQueue,
            .clearingStateOutgoingMutations(storageAdapter),
            .cleaningUp(error),
            .cleaningUpForTermination,
            .schedulingRestart(error),
            .terminate
        ]

        /// Fails the subscriptions of a state machine in `state`, returning its new state and how often it published
        func failSubscriptions(in state: RemoteSyncEngine.State) -> (RemoteSyncEngine.State, Int) {
            let stateMachine = StateMachine(initialState: state, resolver: RemoteSyncEngine.Resolver.resolve(currentState:action:))
            let publications = AtomicValue(initialValue: 0)
            let sink = stateMachine.$state.dropFirst().sink { _ in _ = publications.increment() }
            stateMachine.notify(action: .errored(error), if: RemoteSyncEngine.hasSubscriptions)
            sink.cancel()
            return (stateMachine.state, publications.get())
        }

        for state in withSubscriptions {
            XCTAssertEqual(failSubscriptions(in: state).0.displayName, "cleaningUp", "From \(state.displayName)")
        }
        for state in withoutSubscriptions {
            let (newState, publications) = failSubscriptions(in: state)
            XCTAssertEqual(newState.displayName, state.displayName)
            XCTAssertEqual(publications, 0, "\(state.displayName) was republished")
        }
    }
}
