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

public class AWSS3StorageListOperation: AmplifyOperation<Void, StorageListResult, StorageListError>,
    StorageListOperation {

    let request: AWSS3StorageListRequest
    let storageService: AWSS3StorageServiceBehaviour
    let authService: AWSAuthServiceBehavior
    let onEvent: ((AsyncEvent<Void, StorageListResult, StorageListError>) -> Void)?

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
            // TODO figure this out
            //let error = identityIdResult.mapError
            let error = StorageListError.unknown("identity", "identity")
            dispatch(error)
            finish()
            return
        }

        storageService.execute(request, identityId: identityId, onEvent: onEventHandler)
    }

    private func onEventHandler(event: StorageEvent<Void, Void, StorageListResult, StorageListError>) {
        switch event {
        case .initiated:
            break
        case .inProcess:
            break
        case .completed(let result):
            dispatch(result)
            finish()
        case .failed(let error):
            dispatch(error)
            finish()
        }
    }

    private func dispatch(_ result: StorageListResult) {
        let asyncEvent = AsyncEvent<Void, StorageListResult, StorageListError>.completed(result)
        dispatch(event: asyncEvent)
        onEvent?(asyncEvent)
    }

    private func dispatch(_ error: StorageListError) {
        let asyncEvent = AsyncEvent<Void, StorageListResult, StorageListError>.failed(error)
        onEvent?(asyncEvent)
        dispatch(event: asyncEvent)
    }
}
