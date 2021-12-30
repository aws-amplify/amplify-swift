//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSPluginsCore
import Combine

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSDataStorePlugin

typealias OnSubmitCallBack = (MutationEvent) -> Void
class MockRemoteSyncEngine: RemoteSyncEngineBehavior {

    let remoteSyncTopicPublisher: PassthroughSubject<RemoteSyncEngineEvent, DataStoreError>
    var callbackOnSubmit: OnSubmitCallBack?
    var returnOnSubmit: ((MutationEvent) -> Future<MutationEvent, DataStoreError>)?

    var publisher: AnyPublisher<RemoteSyncEngineEvent, DataStoreError> {
        return remoteSyncTopicPublisher.eraseToAnyPublisher()
    }

    init() {
        self.remoteSyncTopicPublisher = PassthroughSubject<RemoteSyncEngineEvent, DataStoreError>()
    }
    func start(api: APICategoryGraphQLBehavior, auth: AuthCategoryBehavior?) {

    }

    func stop(completion: @escaping DataStoreCallback<Void>) {

    }

    @available(iOS 13.0, *)
    func submit(_ mutationEvent: MutationEvent) -> Future<MutationEvent, DataStoreError> {
        if let callback = callbackOnSubmit {
            callback(mutationEvent)
        }
        if let returnOnSubmit = self.returnOnSubmit {
            return returnOnSubmit(mutationEvent)
        }
        return Future<MutationEvent, DataStoreError> { promise in
            promise(.success(mutationEvent))
        }
    }

    func setCallbackOnSubmit(callback: @escaping OnSubmitCallBack) {
        callbackOnSubmit = callback
    }
    func setReturnOnSubmit(_ returnOnSubmit: @escaping (MutationEvent) -> Future<MutationEvent, DataStoreError>) {
        self.returnOnSubmit = returnOnSubmit
    }
}
