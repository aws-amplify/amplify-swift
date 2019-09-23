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

public class AWSS3StorageListOperation: AmplifyOperation<Void, StorageListResult, StorageError>,
    StorageListOperation {

    let request: AWSS3StorageListRequest
    let storageService: AWSS3StorageServiceBehaviour
    let authService: AWSAuthServiceBehavior
    let onEvent: ((AsyncEvent<Void, StorageListResult, StorageError>) -> Void)?

    init(_ request: AWSS3StorageListRequest,
         storageService: AWSS3StorageServiceBehaviour,
         authService: AWSAuthServiceBehavior,
         onEvent: ((AsyncEvent<Void, CompletedType, ErrorType>) -> Void)?) {

        self.request = request
        self.storageService = storageService
        self.onEvent = onEvent
        self.authService = authService
        super.init(categoryType: .storage)
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

        let accessLevelPrefix = StorageRequestUtils.getAccessLevelPrefix(accessLevel: request.accessLevel,
                                                                         identityId: identityId,
                                                                         targetIdentityId: request.targetIdentityId)

        if isCancelled {
            finish()
            return
        }

        storageService.list(prefix: accessLevelPrefix, path: request.path, onEvent: onEventHandler)
    }

    private func onEventHandler(event: StorageEvent<Void, Void, StorageListResult, StorageError>) {
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

    private func dispatch(_ result: StorageListResult) {
        let asyncEvent = AsyncEvent<Void, StorageListResult, StorageError>.completed(result)
        dispatch(event: asyncEvent)
        onEvent?(asyncEvent)
    }

    private func dispatch(_ error: StorageError) {
        let asyncEvent = AsyncEvent<Void, StorageListResult, StorageError>.failed(error)
        onEvent?(asyncEvent)
        dispatch(event: asyncEvent)
    }
}
