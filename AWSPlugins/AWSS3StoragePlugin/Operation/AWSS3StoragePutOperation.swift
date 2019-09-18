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

public class AWSS3StoragePutOperation: AmplifyOperation<Progress, String, StoragePutError>,
    StoragePutOperation {

    let request: AWSS3StoragePutRequest
    let storageService: AWSS3StorageServiceBehaviour
    let authService: AWSAuthServiceBehavior
    let onEvent: ((AsyncEvent<Progress, String, StoragePutError>) -> Void)?

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
            let asyncEvent = AsyncEvent<Progress, String, StoragePutError>.failed(error)
            self.onEvent?(asyncEvent)
            self.dispatch(event: asyncEvent)
            finish()
            return
        }

        let identityIdResult = authService.getIdentityId()

        guard case let .success(identityId) = identityIdResult else {
            if case let .failure(error) = identityIdResult {
                let storagePutError = StoragePutError.identity(error.errorDescription, error.recoverySuggestion)
                dispatch(storagePutError)
            }

            finish()
            return
        }

        let uploadSizeResult = StorageRequestUtils.getSize(request.uploadSource)

        guard case let .success(uploadSize) = uploadSizeResult else {
            if case let .failure(error) = uploadSizeResult {
                dispatch(error)
            }

            finish()
            return
        }

        let serviceKey = StorageRequestUtils.getServiceKey(accessLevel: request.accessLevel,
                                                           identityId: identityId,
                                                           key: request.key)
        let serviceMetadata = StorageRequestUtils.getServiceMetadata(request.metadata)

        if uploadSize > PluginConstants.multiPartUploadSizeThreshold {
            storageService.multiPartUpload(serviceKey: serviceKey,
                                           uploadSource: request.uploadSource,
                                           contentType: request.contentType,
                                           metadata: serviceMetadata,
                                           onEvent: onEventHandler)
        } else {
            storageService.upload(serviceKey: serviceKey,
                                  uploadSource: request.uploadSource,
                                  contentType: request.contentType,
                                  metadata: serviceMetadata,
                                  onEvent: onEventHandler)
        }
    }

    private func onEventHandler(
        event: StorageEvent<StorageOperationReference, Progress, Void, StorageServiceError>) {
        switch event {
        case .initiated(let reference):
            storageOperationReference = reference
        case .inProcess(let progress):
            dispatch(progress)
        case .completed:
            dispatch(request.key)
            finish()
        case .failed(let error):
            let storagePutError = StoragePutError.service(error.errorDescription, error.recoverySuggestion)
            dispatch(storagePutError)
            finish()
        }
    }

    private func dispatch(_ progress: Progress) {
        let asyncEvent = AsyncEvent<Progress, String, StoragePutError>.inProcess(progress)
        dispatch(event: asyncEvent)
        onEvent?(asyncEvent)
    }

    private func dispatch(_ result: String) {
        let asyncEvent = AsyncEvent<Progress, String, StoragePutError>.completed(result)
        dispatch(event: asyncEvent)
        onEvent?(asyncEvent)
    }

    private func dispatch(_ error: StoragePutError) {
        let asyncEvent = AsyncEvent<Progress, String, StoragePutError>.failed(error)
        onEvent?(asyncEvent)
        dispatch(event: asyncEvent)
    }
}
