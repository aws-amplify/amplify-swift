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

public class AWSS3StoragePutOperation: AmplifyOperation<Progress, StoragePutResult, StoragePutError>,
    StoragePutOperation {

    let request: AWSS3StoragePutRequest
    let storageService: AWSS3StorageServiceBehaviour
    let authService: AWSAuthServiceBehavior
    let onEvent: ((AsyncEvent<Progress, StoragePutResult, StoragePutError>) -> Void)?

    var storageOperationReference: StorageOperationReference?

    init(_ request: AWSS3StoragePutRequest,
         storageService: AWSS3StorageServiceBehaviour,
         authService: AWSAuthServiceBehavior,
         onEvent: ((AsyncEvent<Progress, CompletedType, ErrorType>) -> Void)?) {

        self.request = request
        self.storageService = storageService
        self.authService = authService
        self.onEvent = onEvent
        super.init(categoryType: .storage)
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
            let asyncEvent = AsyncEvent<Progress, StoragePutResult, StoragePutError>.failed(error)
            self.onEvent?(asyncEvent)
            self.dispatch(event: asyncEvent)
            finish()
            return
        }

        let identityIdResult = authService.getIdentityId()

        guard case let .success(identityId) = identityIdResult else {
            // TODO figure this out
            //let error = identityIdResult.mapError
            let error = StoragePutError.unknown("identity", "identity")
            dispatch(error)
            finish()
            return
        }

        storageService.execute(request, identityId: identityId, onEvent: onEventHandler)
    }

    private func onEventHandler(
        event: StorageEvent<StorageOperationReference, Progress, StoragePutResult, StoragePutError>) {
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
        let asyncEvent = AsyncEvent<Progress, StoragePutResult, StoragePutError>.inProcess(progress)
        dispatch(event: asyncEvent)
        onEvent?(asyncEvent)
    }

    private func dispatch(_ result: StoragePutResult) {
        let asyncEvent = AsyncEvent<Progress, StoragePutResult, StoragePutError>.completed(result)
        dispatch(event: asyncEvent)
        onEvent?(asyncEvent)
    }

    private func dispatch(_ error: StoragePutError) {
        let asyncEvent = AsyncEvent<Progress, StoragePutResult, StoragePutError>.failed(error)
        onEvent?(asyncEvent)
        dispatch(event: asyncEvent)
    }
}
