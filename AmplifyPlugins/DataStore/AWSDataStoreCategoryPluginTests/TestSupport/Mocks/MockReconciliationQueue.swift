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
@testable import AWSDataStoreCategoryPlugin

final class MockReconciliationQueue: MessageReporter, IncomingEventReconciliationQueue {

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
