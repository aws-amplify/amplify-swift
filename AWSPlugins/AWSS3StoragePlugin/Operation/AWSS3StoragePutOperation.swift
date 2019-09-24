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

public class AWSS3StoragePutOperation: AmplifyOperation<Progress, String, StorageError>,
    StoragePutOperation {

    let request: AWSS3StoragePutRequest
    let storageService: AWSS3StorageServiceBehaviour
    let authService: AWSAuthServiceBehavior
    let onEvent: ((AsyncEvent<Progress, String, StorageError>) -> Void)?

    var storageTaskReference: StorageTaskReference?

    /// Serial queue for synchronizing access to `storageTaskReference`.
    private let storageTaskActionQueue = DispatchQueue(label: "com.amazonaws.amplify.StorageTaskActionQueue")

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

    override public func pause() {
        storageTaskActionQueue.async {
            self.storageTaskReference?.pause()
            super.pause()
        }
    }

    override public func resume() {
        storageTaskActionQueue.async {
            self.storageTaskReference?.resume()
            super.resume()
        }
    }

    override public func cancel() {
        storageTaskActionQueue.async {
            self.storageTaskReference?.cancel()
            super.cancel()
        }
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
                dispatch(error)
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

        if isCancelled {
            finish()
            return
        }

        if uploadSize > AWSS3StoragePutRequest.multiPartUploadSizeThreshold {
            storageService.multiPartUpload(serviceKey: serviceKey,
                                           uploadSource: request.uploadSource,
                                           contentType: request.contentType,
                                           metadata: serviceMetadata) { [weak self] event in
                                               self?.onEventHandler(event: event)
                                           }
        } else {
            storageService.upload(serviceKey: serviceKey,
                                  uploadSource: request.uploadSource,
                                  contentType: request.contentType,
                                  metadata: serviceMetadata) { [weak self] event in
                                      self?.onEventHandler(event: event)
                                  }
        }
    }

    private func onEventHandler(
        event: StorageEvent<StorageTaskReference, Progress, Void, StorageError>) {
        switch event {
        case .initiated(let reference):
            storageTaskActionQueue.async {
                self.storageTaskReference = reference
                if self.isCancelled {
                    self.storageTaskReference?.cancel()
                    self.finish()
                }
            }
        case .inProcess(let progress):
            dispatch(progress)
        case .completed:
            dispatch(request.key)
            finish()
        case .failed(let error):
            dispatch(error)
            finish()
        }
    }

    private func dispatch(_ progress: Progress) {
        let asyncEvent = AsyncEvent<Progress, String, StorageError>.inProcess(progress)
        dispatch(event: asyncEvent)
        onEvent?(asyncEvent)
    }

    private func dispatch(_ result: String) {
        let asyncEvent = AsyncEvent<Progress, String, StorageError>.completed(result)
        dispatch(event: asyncEvent)
        onEvent?(asyncEvent)
    }

    private func dispatch(_ error: StorageError) {
        let asyncEvent = AsyncEvent<Progress, String, StorageError>.failed(error)
        onEvent?(asyncEvent)
        dispatch(event: asyncEvent)
    }
}
