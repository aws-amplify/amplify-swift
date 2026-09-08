//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPluginsCore
import Combine
import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

// `@unchecked Sendable`: the protocol it conforms to now requires `Sendable`. Test double driven

// by a single test at a time.

class MockAWSInitialSyncOrchestrator: InitialSyncOrchestrator, @unchecked Sendable {
    static let factory: InitialSyncOrchestratorFactory = {
        dataStoreConfiguration, _, api, reconciliationQueue, storageAdapter  in
        MockAWSInitialSyncOrchestrator(
            dataStoreConfiguration: dataStoreConfiguration,
            api: api,
            reconciliationQueue: reconciliationQueue,
            storageAdapter: storageAdapter
        )
    }

    typealias SyncOperationResult = Result<Void, DataStoreError>
    typealias SyncOperationResultHandler = (SyncOperationResult) -> Void

    /// `AtomicValue` rather than `nonisolated(unsafe) static var`: this outlives an individual test, and
    /// the sync engine keeps a strong reference that can fire `sync(completion:)` during teardown — so a
    /// `reset()` from the next test's `setUp` can overlap a read from the previous test's engine. XCTest
    /// running one test at a time does not cover that, which is what the previous annotation assumed.
    ///
    /// The unused `instance` static that sat here was dead and has been removed.
    private static let mockedResponse = AtomicValue<SyncOperationResult?>(initialValue: nil)

    let initialSyncOrchestratorTopic: PassthroughSubject<InitialSyncOperationEvent, DataStoreError>
    var publisher: AnyPublisher<InitialSyncOperationEvent, DataStoreError> {
        return initialSyncOrchestratorTopic.eraseToAnyPublisher()
    }

    init(
        dataStoreConfiguration: DataStoreConfiguration,
        api: APICategoryGraphQLBehavior?,
        reconciliationQueue: IncomingEventReconciliationQueue?,
        storageAdapter: StorageEngineAdapter?
    ) {
        self.initialSyncOrchestratorTopic = PassthroughSubject<InitialSyncOperationEvent, DataStoreError>()
    }

    static func reset() {
        mockedResponse.set(nil)
    }

    static func setResponseOnSync(result: SyncOperationResult) {
        mockedResponse.set(result)
    }

    func sync(completion: @escaping SyncOperationResultHandler) {
        let response = MockAWSInitialSyncOrchestrator.mockedResponse.get() ?? .successfulVoid
        completion(response)
    }
}
