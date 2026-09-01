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

    // `nonisolated(unsafe)`: set by a test's `setUpWithError` before use and read after; XCTest runs
    // one test at a time.
    nonisolated(unsafe) private static var instance: MockAWSInitialSyncOrchestrator?
    nonisolated(unsafe) private static var mockedResponse: SyncOperationResult?

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
        mockedResponse = nil
    }

    static func setResponseOnSync(result: SyncOperationResult) {
        mockedResponse = result
    }

    func sync(completion: @escaping SyncOperationResultHandler) {
        let response = MockAWSInitialSyncOrchestrator.mockedResponse ?? .successfulVoid
        completion(response)
    }
}
