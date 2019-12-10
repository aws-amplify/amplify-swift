//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
@testable import AWSDataStoreCategoryPlugin

struct NoOpInitialSyncOrchestrator: InitialSyncOrchestrator {
    static let factory: InitialSyncOrchestratorFactory = { _, _, _ in
        NoOpInitialSyncOrchestrator()
    }

    func sync(completion: @escaping (Result<Void, DataStoreError>) -> Void) {
        completion(Result.successfulVoid)
    }
}
