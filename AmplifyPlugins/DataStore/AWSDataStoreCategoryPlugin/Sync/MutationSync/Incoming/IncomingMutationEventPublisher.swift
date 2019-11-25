//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

/// Facade to hide the AsyncEventQueue/ModelMapper structures from the ReconciliationQueue
final class IncomingMutationEventPublisher {

    private let asyncEvents: IncomingAsyncMutationEventSubject
    private let mapper: AsyncMutationEventToAnyModelMapper

    var incomingAsyncMutationEvents: IncomingAsyncMutationEventSubject.Subject {
        asyncEvents.incomingAsyncMutationEvents
    }

    var publisher: AnyPublisher<AnyModel, DataStoreError> {
        mapper.publisher
    }

    init(modelType: Model.Type, api: APICategoryGraphQLBehavior) {
        self.asyncEvents = IncomingAsyncMutationEventSubject()

        let mapper = AsyncMutationEventToAnyModelMapper()
        self.mapper = mapper

        asyncEvents.subscribe(subscriber: mapper)
    }

}
