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

typealias OnSubmitCallBack = (MutationEvent) -> Result<MutationEvent, DataStoreError>

class MockRemoteSyncEngine: RemoteSyncEngineBehavior {

    let remoteSyncTopicPublisher: PassthroughSubject<RemoteSyncEngineEvent, DataStoreError>
    var callbackOnSubmit: OnSubmitCallBack?
    var success = true

    var publisher: AnyPublisher<RemoteSyncEngineEvent, DataStoreError> {
        return remoteSyncTopicPublisher.eraseToAnyPublisher()
    }

    init() {
        self.remoteSyncTopicPublisher = PassthroughSubject<RemoteSyncEngineEvent, DataStoreError>()
    }
    func start(api: APICategoryGraphQLBehaviorExtended, auth: AuthCategoryBehavior?) {

    }

    func stop(completion: @escaping DataStoreCallback<Void>) {

    }

    func setCallbackOnSubmit(callbackOnSubmit: @escaping OnSubmitCallBack) {
        self.callbackOnSubmit = callbackOnSubmit
    }

    func submit(_ mutationEvent: MutationEvent) -> Result<MutationEvent, DataStoreError> {
        if let callback = callbackOnSubmit {
            return callback(mutationEvent)
        } else {
            return .success(mutationEvent)
        }
    }

}
