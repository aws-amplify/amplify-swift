//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
@testable import AWSDataStoreCategoryPlugin

struct NoOpInitialSyncOrchestrator: InitialSyncOrchestrator {
    static let factory: InitialSyncOrchestratorFactory = { _, _, _, _ in
        NoOpInitialSyncOrchestrator()
    }

    func sync(completion: @escaping (Result<ModelSyncedPayload?, DataStoreError>) -> Void) {
        completion(Result.success(nil))
    }
}
