//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

/// Storage Get URL Operation.
///
/// See: [Operations] for more details.
///
/// [Operations]: https://github.com/aws-amplify/amplify-ios/blob/main/OPERATIONS.md
public class AWSS3StorageGetURLOperation: AmplifyOperation<
    StorageGetURLRequest,
    URL,
    StorageError
>, StorageGetURLOperation {

    let storageConfiguration: AWSS3StoragePluginConfiguration
    let storageService: AWSS3StorageServiceBehaviour
    let authService: AWSAuthServiceBehavior

    init(_ request: StorageGetURLRequest,
         storageConfiguration: AWSS3StoragePluginConfiguration,
         storageService: AWSS3StorageServiceBehaviour,
         authService: AWSAuthServiceBehavior,
         resultListener: ResultListener?) {

        self.storageConfiguration = storageConfiguration
        self.storageService = storageService
        self.authService = authService
        super.init(categoryType: .storage,
                   eventName: HubPayload.EventName.Storage.getURL,
                   request: request,
                   resultListener: resultListener)
    }

    /// Cancels operation.
    override public func cancel() {
        super.cancel()
    }

    /// Performs the task to get URL.
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

        let prefixResolver = storageConfiguration.prefixResolver ??
            StorageAccessLevelAwarePrefixResolver(authService: authService)
        prefixResolver.resolvePrefix(for: request.options.accessLevel,
                                        targetIdentityId: request.options.targetIdentityId) { prefixResolution in
            switch prefixResolution {
            case .success(let prefix):
                let serviceKey = prefix + self.request.key
                self.storageService.getPreSignedURL(serviceKey: serviceKey,
                                                    expires: self.request.options.expires) { [weak self] event in
                    self?.onServiceEvent(event: event)
                }
            case .failure(let error):
                self.dispatch(error)
                self.finish()
            }
        }

    }

    private func onServiceEvent(event: StorageEvent<Void, Void, URL, StorageError>) {
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

    private func dispatch(_ result: URL) {
        let result = OperationResult.success(result)
        dispatch(result: result)
    }

    private func dispatch(_ error: StorageError) {
        let result = OperationResult.failure(error)
        dispatch(result: result)
    }
}
