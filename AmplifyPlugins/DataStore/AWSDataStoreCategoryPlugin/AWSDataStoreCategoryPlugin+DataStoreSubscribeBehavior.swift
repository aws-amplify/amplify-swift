//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

extension AWSDataStoreCategoryPlugin: DataStoreSubscribeBehavior {
    @available(iOS 13.0, *)
    public func publisher<M: Model>(for modelType: M.Type)
        -> AnyPublisher<MutationEvent, DataStoreError> {
            return dataStorePublisher.publisher(for: modelType)
    }
}
