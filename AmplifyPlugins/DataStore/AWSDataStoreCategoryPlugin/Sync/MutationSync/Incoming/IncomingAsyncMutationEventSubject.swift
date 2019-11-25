//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Combine

/// Vends a subject that mutation listeners can send responses to. Performs no work on its own, but rather depends on
/// downstream subscribers (such as an AsyncEvent->AnyModel mapper) to convert and re-publish events.
final class IncomingAsyncMutationEventSubject {
    typealias Event = AsyncEvent<Void, GraphQLResponse<AnyModel>, APIError>
    typealias Subject = PassthroughSubject<IncomingAsyncMutationEventSubject.Event, DataStoreError>

    let incomingAsyncMutationEvents: Subject

    init() {
        self.incomingAsyncMutationEvents = Subject()
    }

    func subscribe<S: Subscriber>(subscriber: S) where S.Input == Event, S.Failure == DataStoreError {
        incomingAsyncMutationEvents.subscribe(subscriber)
    }

}
