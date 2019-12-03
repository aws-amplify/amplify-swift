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
@available(iOS 13.0, *)
final class IncomingMutationEventFacade {

    private let asyncEvents: IncomingAsyncSubscriptionEventPublisher
    private let mapper: IncomingAsyncSubscriptionEventToAnyModelMapper

    var publisher: AnyPublisher<MutationSync<AnyModel>, DataStoreError> {
        mapper.publisher
    }

    init(modelType: Model.Type, api: APICategoryGraphQLBehavior) {
        self.asyncEvents = IncomingAsyncSubscriptionEventPublisher(modelType: modelType,
                                                                   api: api)

        let mapper = IncomingAsyncSubscriptionEventToAnyModelMapper()
        self.mapper = mapper

        asyncEvents.subscribe(subscriber: mapper)
    }

    func reset(onComplete: () -> Void) {
        let group = DispatchGroup()

        group.enter()
        DispatchQueue.global().async {
            self.asyncEvents.reset { group.leave() }
        }

        group.enter()
        DispatchQueue.global().async {
            self.mapper.reset { group.leave() }
        }

        group.wait()
        onComplete()
    }

}
