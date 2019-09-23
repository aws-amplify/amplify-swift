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

// TODO: thread safety: everything has to be locked down
// TODO verify no retain cycle
public class AWSS3StorageGetURLOperation: AmplifyOperation<Void, URL, StorageError>,
    StorageGetURLOperation {

    let request: AWSS3StorageGetURLRequest
    let storageService: AWSS3StorageServiceBehaviour
    let authService: AWSAuthServiceBehavior
    let onEvent: ((AsyncEvent<Void, URL, StorageError>) -> Void)?

    init(_ request: AWSS3StorageGetURLRequest,
         storageService: AWSS3StorageServiceBehaviour,
         authService: AWSAuthServiceBehavior,
         onEvent: ((AsyncEvent<Void, CompletedType, ErrorType>) -> Void)?) {

        self.request = request
        self.storageService = storageService
        self.authService = authService
        self.onEvent = onEvent
        super.init(categoryType: .storage)
        // TODO pass onEvent to the Hub
    }

    override public func cancel() {
        super.cancel()
    }

    override public func main() {
        if isCancelled {
            finish()
            return
        }
        
        if let error = request.validate() {
            dispatch(error)
            finish()
            return
        }

        let identityIdResult = authService.getIdentityId()
        guard case let .success(identityId) = identityIdResult else {
            if case let .failure(error) = identityIdResult {
                dispatch(StorageError.identity(error.errorDescription, error.recoverySuggestion))
            }

            finish()
            return
        }

        let serviceKey = StorageRequestUtils.getServiceKey(accessLevel: request.accessLevel,
                                                           identityId: identityId,
                                                           key: request.key,
                                                           targetIdentityId: request.targetIdentityId)

        if isCancelled {
            finish()
            return
        }

        storageService.getPreSignedURL(serviceKey: serviceKey,
                                       expires: request.expires,
                                       onEvent: onEventHandler)
    }

    private func onEventHandler(event: StorageEvent<Void, Void, URL, StorageError>) {
        switch event {
        case .completed(let result):
            dispatch(result)
            finish()
        case .failed(let error):
            dispatch(error)
            finish()
        default:
            break
        }
    }

    private func dispatch(_ result: URL) {
        let asyncEvent = AsyncEvent<Void, URL, StorageError>.completed(result)
        onEvent?(asyncEvent)
        dispatch(event: asyncEvent)
    }

    private func dispatch(_ error: StorageError) {
        let asyncEvent = AsyncEvent<Void, URL, StorageError>.failed(error)
        onEvent?(asyncEvent)
        dispatch(event: asyncEvent)
    }
}
