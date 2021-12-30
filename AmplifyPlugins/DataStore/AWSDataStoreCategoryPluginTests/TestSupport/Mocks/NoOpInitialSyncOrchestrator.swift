//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine

@testable import Amplify
@testable import AWSDataStorePlugin

struct NoOpInitialSyncOrchestrator: InitialSyncOrchestrator {
    private let initialSyncOrchestratorTopic: PassthroughSubject<InitialSyncOperationEvent, DataStoreError>
    var publisher: AnyPublisher<InitialSyncOperationEvent, DataStoreError> {
        return initialSyncOrchestratorTopic.eraseToAnyPublisher()
    }

    static let factory: InitialSyncOrchestratorFactory = { _, _, _, _, _  in
        let initialSyncOrchestratorTopic = PassthroughSubject<InitialSyncOperationEvent, DataStoreError>()
        let noOpInitialSyncOrchestrator = NoOpInitialSyncOrchestrator(initialSyncOrchestratorTopic: initialSyncOrchestratorTopic)
        return noOpInitialSyncOrchestrator
    }

    func sync(completion: @escaping (Result<Void, DataStoreError>) -> Void) {
        completion(Result.successfulVoid)
    }
}
