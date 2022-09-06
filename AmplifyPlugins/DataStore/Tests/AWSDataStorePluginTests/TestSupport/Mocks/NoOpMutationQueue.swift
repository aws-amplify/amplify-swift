//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import Amplify
@testable import AWSDataStorePlugin
import AWSPluginsCore
import Combine

/// A mutation queue that takes no action on either pause or start, to let these unit tests operate on the
/// mutation queue without interference from the mutation queue polling for events and marking them in-process.
class NoOpMutationQueue: OutgoingMutationQueueBehavior {
    func stopSyncingToCloud(_ completion: @escaping BasicClosure = {}) {
        completion()
    }

    func startSyncingToCloud(api: APICategoryGraphQLBehaviorExtended,
                             mutationEventPublisher: MutationEventPublisher,
                             reconciliationQueue: IncomingEventReconciliationQueue?) {
        // do nothing
    }

    var publisher: AnyPublisher<MutationEvent, Never> {
        return PassthroughSubject<MutationEvent, Never>().eraseToAnyPublisher()
    }
}
