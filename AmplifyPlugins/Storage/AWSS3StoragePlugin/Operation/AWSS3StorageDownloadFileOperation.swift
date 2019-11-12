//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore
import AWSS3

// TODO: thread safety: everything has to be locked down
// TODO verify no retain cycle
public class AWSS3StorageDownloadFileOperation: AmplifyOperation<StorageDownloadFileRequest, Progress,
Void, StorageError>, StorageDownloadFileOperation {

    let storageService: AWSS3StorageServiceBehaviour
    let authService: AWSAuthServiceBehavior

    var storageTaskReference: StorageTaskReference?

    /// Serial queue for synchronizing access to `storageTaskReference`.
    private let storageTaskActionQueue = DispatchQueue(label: "com.amazonaws.amplify.StorageTaskActionQueue")

    init(_ request: StorageDownloadFileRequest,
         storageService: AWSS3StorageServiceBehaviour,
         authService: AWSAuthServiceBehavior,
         listener: EventListener?) {

        self.storageService = storageService
        self.authService = authService
        super.init(categoryType: .storage,
                   eventName: HubPayload.EventName.Storage.downloadFile,
                   request: request,
                   listener: listener)
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
                dispatch(StorageError.authError(error.errorDescription, error.recoverySuggestion))
            }

            finish()
            return
        }

        let serviceKey = StorageRequestUtils.getServiceKey(accessLevel: request.options.accessLevel,
                                                           identityId: identityId,
                                                           key: request.key,
                                                           targetIdentityId: request.options.targetIdentityId)

        if isCancelled {
            finish()
            return
        }

        storageService.download(serviceKey: serviceKey, fileURL: request.local) { [weak self] event in
            self?.onServiceEvent(event: event)
        }
    }

    private func onServiceEvent(event: StorageEvent<StorageTaskReference, Progress, Data?, StorageError>) {
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
            dispatch()
            finish()
        case .failed(let error):
            dispatch(error)
            finish()
        }
    }

    private func dispatch(_ progress: Progress) {
        let asyncEvent = AsyncEvent<Progress, Void, StorageError>.inProcess(progress)
        dispatch(event: asyncEvent)
    }

    private func dispatch() {
        let asyncEvent = AsyncEvent<Progress, Void, StorageError>.completed(())
        dispatch(event: asyncEvent)
    }

    private func dispatch(_ error: StorageError) {
        let asyncEvent = AsyncEvent<Progress, Void, StorageError>.failed(error)
        dispatch(event: asyncEvent)
    }
}
