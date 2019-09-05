//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSS3
import AWSMobileClient

public class AWSS3StorageRemoveOperation: AmplifyOperation<Void, StorageRemoveResult, StorageRemoveError>,
    StorageRemoveOperation {

    let request: AWSS3StorageRemoveRequest
    let storageService: AWSS3StorageServiceBehaviour
    let authService: AWSAuthServiceBehavior
    let onEvent: ((AsyncEvent<Void, StorageRemoveResult, StorageRemoveError>) -> Void)?

    init(_ request: AWSS3StorageRemoveRequest,
         storageService: AWSS3StorageServiceBehaviour,
         authService: AWSAuthServiceBehavior,
         onEvent: ((AsyncEvent<Void, StorageRemoveResult, StorageRemoveError>) -> Void)?) {

        self.request = request
        self.storageService = storageService
        self.authService = authService
        self.onEvent = onEvent
        super.init(categoryType: .storage)
    }

    override public func cancel() {
        cancel()
    }

    override public func main() {
        if let error = request.validate() {
            self.dispatch(error)
            finish()
            return
        }

        let identityIdResult = authService.getIdentityId()

        guard case let .success(identityId) = identityIdResult else {
            if case let .failure(error) = identityIdResult {
                let storageRemoveError = StorageRemoveError.identity(error.errorDescription, error.recoverySuggestion)
                dispatch(storageRemoveError)
            }

            finish()
            return
        }

        let serviceKey = StorageRequestUtils.getServiceKey(accessLevel: request.accessLevel,
                                                           identityId: identityId,
                                                           key: request.key)

        storageService.delete(bucket: request.bucket,
                              serviceKey: serviceKey,
                              onEvent: onEventHandler)
    }

    private func onEventHandler(event: StorageEvent<Void, Void, StorageRemoveResult, StorageRemoveError>) {
        switch event {
        case .initiated:
            break
        case .inProcess:
            break
        case .completed(let result):
            dispatch(result)
            finish()
        case .failed(let error):
            dispatch(error)
            finish()
        }
    }

    private func dispatch(_ result: StorageRemoveResult) {
        let asyncEvent = AsyncEvent<Void, StorageRemoveResult, StorageRemoveError>.completed(result)
        onEvent?(asyncEvent)
        dispatch(event: asyncEvent)
    }

    private func dispatch(_ error: StorageRemoveError) {
        let asyncEvent = AsyncEvent<Void, StorageRemoveResult, StorageRemoveError>.failed(error)
        onEvent?(asyncEvent)
        dispatch(event: asyncEvent)
    }
}
