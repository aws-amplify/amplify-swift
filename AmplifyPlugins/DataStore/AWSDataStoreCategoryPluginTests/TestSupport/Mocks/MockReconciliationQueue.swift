//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
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

    func offer(_ remoteModel: MutationSync<AnyModel>, modelSchema: ModelSchema) {
        notify("offer(_:) remoteModel: \(remoteModel)")
    }

    var publisher: AnyPublisher<IncomingEventReconciliationQueueEvent, DataStoreError> {
        return PassthroughSubject<IncomingEventReconciliationQueueEvent, DataStoreError>().eraseToAnyPublisher()
    }

    func cancel() {
        //no-op for mock
    }
}
