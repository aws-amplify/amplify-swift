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
public class AWSS3StorageGetDataOperation: AmplifyOperation<Progress, Data, StorageError>,
    StorageGetDataOperation {

    let request: AWSS3StorageGetDataRequest
    let storageService: AWSS3StorageServiceBehaviour
    let authService: AWSAuthServiceBehavior
    let onEvent: ((AsyncEvent<Progress, Data, StorageError>) -> Void)?

    var storageOperationReference: StorageOperationReference?

    /// Concurrent queue for synchronizing access to `storageOperationReference`.
    private let taskQueue = DispatchQueue(label: Bundle.main.bundleIdentifier! + ".rw.task", attributes: .concurrent)

    init(_ request: AWSS3StorageGetDataRequest,
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
            self.storageOperationReference?.pause()
        }
    }

    public func resume() {
        taskQueue.async(flags: .barrier) {
            self.storageOperationReference?.resume()
        }
    }

    override public func cancel() {
        taskQueue.async(flags: .barrier) {
            self.storageOperationReference?.cancel()
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

        if isCancelled {
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

        if isCancelled {
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
                                fileURL: nil,
                                onEvent: onEventHandler)
    }

    private func onEventHandler(event: StorageEvent<StorageOperationReference, Progress, Data?, StorageError>) {
        switch event {
        case .initiated(let reference):
            storageOperationReference = reference
            if isCancelled {
                storageOperationReference?.cancel()
                finish()
            }
        case .inProcess(let progress):
            dispatch(progress)
        case .completed(let result):
            guard let data = result else {
                dispatch(StorageError.unknown("this should never be the case here"))
                finish()
                return
            }

            dispatch(data)
            finish()
        case .failed(let error):
            dispatch(error)
            finish()
        }
    }

    private func dispatch(_ progress: Progress) {
        let asyncEvent = AsyncEvent<Progress, Data, StorageError>.inProcess(progress)
        dispatch(event: asyncEvent)
        onEvent?(asyncEvent)
    }

    private func dispatch(_ result: Data) {
        let asyncEvent = AsyncEvent<Progress, Data, StorageError>.completed(result)
        onEvent?(asyncEvent)
        dispatch(event: asyncEvent)
    }

    private func dispatch(_ error: StorageError) {
        let asyncEvent = AsyncEvent<Progress, Data, StorageError>.failed(error)
        onEvent?(asyncEvent)
        dispatch(event: asyncEvent)
    }
}
