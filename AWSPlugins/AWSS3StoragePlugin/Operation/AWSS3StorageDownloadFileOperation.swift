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
public class AWSS3StorageDownloadFileOperation: AmplifyOperation<Progress, Void, StorageDownloadFileError>,
    StorageDownloadFileOperation {

    let request: AWSS3StorageDownloadFileRequest
    let storageService: AWSS3StorageServiceBehaviour
    let authService: AWSAuthServiceBehavior
    let onEvent: ((AsyncEvent<Progress, Void, StorageDownloadFileError>) -> Void)?

    var storageOperationReference: StorageOperationReference?

    init(_ request: AWSS3StorageDownloadFileRequest,
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
                let storageGetError = StorageDownloadFileError.identity(error.errorDescription, error.recoverySuggestion)
                dispatch(storageGetError)
            }

            finish()
            return
        }

        let serviceKey = StorageRequestUtils.getServiceKey(accessLevel: request.accessLevel,
                                                           identityId: identityId,
                                                           targetIdentityId: request.targetIdentityId,
                                                           key: request.key)
        storageService.download(serviceKey: serviceKey,
                                fileURL: request.local,
                                onEvent: onEventHandler)
    }

    private func onEventHandler(
        event: StorageEvent<StorageOperationReference, Progress, Data?, StorageServiceError>) {
        switch event {
        case .initiated(let reference):
            storageOperationReference = reference
        case .inProcess(let progress):
            dispatch(progress)
        case .completed:
            dispatch()
            finish()
        case .failed(let error):
            let storageDownloadFileError = StorageDownloadFileError.service(
                error.errorDescription, error.recoverySuggestion)
            dispatch(storageDownloadFileError)
            finish()
        }
    }

    private func dispatch(_ progress: Progress) {
        let asyncEvent = AsyncEvent<Progress, Void, StorageDownloadFileError>.inProcess(progress)
        dispatch(event: asyncEvent)
        onEvent?(asyncEvent)
    }

    private func dispatch() {
        let asyncEvent = AsyncEvent<Progress, Void, StorageDownloadFileError>.completed(())
        onEvent?(asyncEvent)
        dispatch(event: asyncEvent)
    }

    private func dispatch(_ error: StorageDownloadFileError) {
        let asyncEvent = AsyncEvent<Progress, Void, StorageDownloadFileError>.failed(error)
        onEvent?(asyncEvent)
        dispatch(event: asyncEvent)
    }
}
