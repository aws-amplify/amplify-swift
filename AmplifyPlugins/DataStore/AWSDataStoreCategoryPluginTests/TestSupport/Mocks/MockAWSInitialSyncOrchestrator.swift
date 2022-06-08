//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSPluginsCore
import Combine

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

class MockAWSInitialSyncOrchestrator: InitialSyncOrchestrator {
    static let factory: InitialSyncOrchestratorFactory = {
        dataStoreConfiguration, _, api, reconciliationQueue, storageAdapter  in
        MockAWSInitialSyncOrchestrator(dataStoreConfiguration: dataStoreConfiguration,
                                       api: api,
                                       reconciliationQueue: reconciliationQueue,
                                       storageAdapter: storageAdapter)
    }

    typealias SyncOperationResult = Result<Void, DataStoreError>
    typealias SyncOperationResultHandler = (SyncOperationResult) -> Void

    private static var instance: MockAWSInitialSyncOrchestrator?
    private static var mockedResponse: SyncOperationResult?

    let initialSyncOrchestratorTopic: PassthroughSubject<InitialSyncOperationEvent, DataStoreError>
    var publisher: AnyPublisher<InitialSyncOperationEvent, DataStoreError> {
        return initialSyncOrchestratorTopic.eraseToAnyPublisher()
    }

    init(dataStoreConfiguration: DataStoreConfiguration,
         api: APICategoryGraphQLBehavior?,
         reconciliationQueue: IncomingEventReconciliationQueue?,
         storageAdapter: StorageEngineAdapter?) {
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
