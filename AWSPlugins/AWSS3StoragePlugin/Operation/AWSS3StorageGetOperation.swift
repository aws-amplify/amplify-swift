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
public class AWSS3StorageGetOperation: AmplifyOperation<Progress, StorageGetResult, StorageGetError>,
    StorageGetOperation {

    let request: AWSS3StorageGetRequest
    let storageService: AWSS3StorageServiceBehaviour
    let authService: AWSAuthServiceBehavior
    let onEvent: ((AsyncEvent<Progress, StorageGetResult, StorageGetError>) -> Void)?

    var storageOperationReference: StorageOperationReference?

    init(_ request: AWSS3StorageGetRequest,
         storageService: AWSS3StorageServiceBehaviour,
         authService: AWSAuthServiceBehavior,
         onEvent: ((AsyncEvent<Progress, CompletedType, ErrorType>) -> Void)?) {

        self.request = request
        self.storageService = storageService
        self.authService = authService
        self.onEvent = onEvent
        super.init(categoryType: .storage)
        // TODO pass onEvent to the Hub
    }

    public func pause() {
        storageOperationReference?.pause()
    }

    public func resume() {
        storageOperationReference?.resume()
    }

    override public func cancel() {
        storageOperationReference?.cancel()
        cancel()
    }

    override public func main() {
        if let error = request.validate() {
            dispatch(error)
            finish()
            return
        }

        let identityIdResult = authService.getIdentityId()

        guard case let .success(identityId) = identityIdResult else {
            if case let .failure(error) = identityIdResult {
                let storageGetError = StorageGetError.identity(error.errorDescription, error.recoverySuggestion)
                dispatch(storageGetError)
            }

            finish()
            return
        }

        let serviceKey = StorageRequestUtils.getServiceKey(accessLevel: request.accessLevel,
                                                           identityId: identityId,
                                                           targetIdentityId: request.targetIdentityId,
                                                           key: request.key)
        switch request.storageGetDestination {
        case .data:
            storageService.download(serviceKey: serviceKey,
                                    fileURL: nil,
                                    onEvent: onEventHandler)
        case .file(let local):
            storageService.download(serviceKey: serviceKey,
                                    fileURL: local,
                                    onEvent: onEventHandler)
        case .url(let expires):
            storageService.getPreSignedURL(serviceKey: serviceKey,
                                           expires: expires,
                                           onEvent: onEventHandler)
        }
    }

    private func onEventHandler(
        event: StorageEvent<StorageOperationReference, Progress, StorageGetResult, StorageGetError>) {
        switch event {
        case .initiated(let reference):
            storageOperationReference = reference
        case .inProcess(let progress):
            dispatch(progress)
        case .completed(let result):
            dispatch(result)
            finish()
        case .failed(let error):
            dispatch(error)
            finish()
        }
    }

    private func dispatch(_ progress: Progress) {
        let asyncEvent = AsyncEvent<Progress, StorageGetResult, StorageGetError>.inProcess(progress)
        dispatch(event: asyncEvent)
        onEvent?(asyncEvent)
    }

    private func dispatch(_ result: StorageGetResult) {
        let asyncEvent = AsyncEvent<Progress, StorageGetResult, StorageGetError>.completed(result)
        onEvent?(asyncEvent)
        dispatch(event: asyncEvent)
    }

    private func dispatch(_ error: StorageGetError) {
        let asyncEvent = AsyncEvent<Progress, StorageGetResult, StorageGetError>.failed(error)
        onEvent?(asyncEvent)
        dispatch(event: asyncEvent)
    }
}
