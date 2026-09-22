//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Combine
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

// `@unchecked Sendable`: the protocol it conforms to now requires `Sendable`. Test double driven

// by a single test at a time.

class MockReconciliationQueue: MessageReporter, IncomingEventReconciliationQueue, @unchecked Sendable {

    func start() {
        notify()
    }

    func pause() {
        notify()
    }

    func offer(_ remoteModels: [MutationSync<AnyModel>], modelName: ModelName) {
        notify("offer(_:) remoteModels: \(remoteModels)")
    }

    var publisher: AnyPublisher<IncomingEventReconciliationQueueEvent, DataStoreError> {
        return PassthroughSubject<IncomingEventReconciliationQueueEvent, DataStoreError>().eraseToAnyPublisher()
    }

    func cancel() {
        // no-op for mock
    }
}
