//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

extension AWSDataStorePlugin: DataStoreSubscribeBehavior {
    @available(iOS 13.0, *)
    public func publisher<M: Model>(for modelType: M.Type)
        -> AnyPublisher<MutationEvent, DataStoreError> {
            reinitStorageEngineIfNeeded()
            // Force-unwrapping: The optional 'dataStorePublisher' is expected
            // to exist for deployment targets >=iOS13.0
            return dataStorePublisher!.publisher(for: modelType)
    }
}
