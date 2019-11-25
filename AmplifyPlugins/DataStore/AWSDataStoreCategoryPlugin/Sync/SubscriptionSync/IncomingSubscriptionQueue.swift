//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Combine

/// Facade to hide the AsyncEventQueue/ModelMapper structures from the ReconciliationQueue. Provides a publisher for
/// all incoming subscription types (onCreate, onUpdate, onDelete) for a single Model type.
final class IncomingSubscriptionQueue {

    private let asyncEventQueue: IncomingSubscriptionAsyncEventQueue
    private let mapper: AsyncEventToAnyModelMapper

    var publisher: AnyPublisher<AnyModel, DataStoreError> {
        mapper.publisher
    }

    init(modelType: Model.Type, api: APICategoryGraphQLBehavior) {
        self.asyncEventQueue = IncomingSubscriptionAsyncEventQueue(modelType: modelType,
                                                                   api: api)

        let mapper = AsyncEventToAnyModelMapper()
        self.mapper = mapper

        asyncEventQueue.subscribe(subscriber: mapper)
    }

}
