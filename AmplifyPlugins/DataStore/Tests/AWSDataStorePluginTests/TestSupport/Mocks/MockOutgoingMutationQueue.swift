//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSPluginsCore
import Combine

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

class MockOutgoingMutationQueue: OutgoingMutationQueueBehavior {
    func stopSyncingToCloud(_ completion: @escaping BasicClosure = {}) {
        completion()
    }

    func startSyncingToCloud(api: APICategoryGraphQLBehaviorExtended,
                             mutationEventPublisher: MutationEventPublisher,
                             reconciliationQueue: IncomingEventReconciliationQueue?) {
        // no-op
    }

    var publisher: AnyPublisher<MutationEvent, Never> {
        return PassthroughSubject<MutationEvent, Never>().eraseToAnyPublisher()
    }
}
