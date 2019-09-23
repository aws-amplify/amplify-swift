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
public class AWSS3StorageDownloadFileOperation: AmplifyOperation<Progress, Void, StorageError>,
    StorageDownloadFileOperation {

    let request: AWSS3StorageDownloadFileRequest
    let storageService: AWSS3StorageServiceBehaviour
    let authService: AWSAuthServiceBehavior
    let onEvent: ((AsyncEvent<Progress, Void, StorageError>) -> Void)?

    var storageTaskReference: StorageTaskReference?

    /// Concurrent queue for synchronizing access to `storageTaskReference`.
    private let taskQueue = DispatchQueue(label: Bundle.main.bundleIdentifier! + ".rw.task", attributes: .concurrent)

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
        taskQueue.async(flags: .barrier) {
            self.storageTaskReference?.pause()
        }
    }

    public func resume() {
        taskQueue.async(flags: .barrier) {
            self.storageTaskReference?.resume()
        }
    }

    override public func cancel() {
        taskQueue.async(flags: .barrier) {
            self.storageTaskReference?.cancel()
        }

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
                dispatch(error)
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

        storageService.download(serviceKey: serviceKey,
                                fileURL: request.local,
                                onEvent: onEventHandler)
    }

    private func onEventHandler(event: StorageEvent<StorageTaskReference, Progress, Data?, StorageError>) {
        switch event {
        case .initiated(let reference):
            storageTaskReference = reference
            if isCancelled {
                storageTaskReference?.cancel()
                finish()
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
        onEvent?(asyncEvent)
    }

    private func dispatch() {
        let asyncEvent = AsyncEvent<Progress, Void, StorageError>.completed(())
        onEvent?(asyncEvent)
        dispatch(event: asyncEvent)
    }

    private func dispatch(_ error: StorageError) {
        let asyncEvent = AsyncEvent<Progress, Void, StorageError>.failed(error)
        onEvent?(asyncEvent)
        dispatch(event: asyncEvent)
    }
}
