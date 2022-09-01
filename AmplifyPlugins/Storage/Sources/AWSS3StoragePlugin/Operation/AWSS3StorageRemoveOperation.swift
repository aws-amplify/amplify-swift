//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

/// Storage Remove Operation.
///
/// See: [Operations] for more details.
///
/// [Operations]: https://github.com/aws-amplify/amplify-ios/blob/main/OPERATIONS.md
public class AWSS3StorageRemoveOperation: AmplifyOperation<
    StorageRemoveRequest,
    String,
    StorageError
>, StorageRemoveOperation {

    let storageConfiguration: AWSS3StoragePluginConfiguration
    let storageService: AWSS3StorageServiceBehaviour
    let authService: AWSAuthServiceBehavior

    init(_ request: StorageRemoveRequest,
         storageConfiguration: AWSS3StoragePluginConfiguration,
         storageService: AWSS3StorageServiceBehaviour,
         authService: AWSAuthServiceBehavior,
         resultListener: ResultListener? = nil) {

        self.storageConfiguration = storageConfiguration
        self.storageService = storageService
        self.authService = authService
        super.init(categoryType: .storage,
                   eventName: HubPayload.EventName.Storage.remove,
                   request: request,
                   resultListener: resultListener)
    }

    /// Cancels operation.
    override public func cancel() {
        super.cancel()
    }

    /// Perform the task to remove item.
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

        Task {
            do {
                let prefix = try await prefixResolver.resolvePrefix(for: request.options.accessLevel, targetIdentityId: nil)
                let serviceKey = prefix + request.key
                storageService.delete(serviceKey: serviceKey) { [weak self] event in
                    self?.onServiceEvent(event: event)
                }
            } catch {
                dispatch(StorageError(error: error))
                finish()
            }
        }
    }

    private func onServiceEvent(event: StorageEvent<Void, Void, Void, StorageError>) {
        switch event {
        case .completed:
            dispatch(request.key)
            finish()
        case .failed(let error):
            dispatch(error)
            finish()
        default:
            break
        }
    }

    private func dispatch(_ result: String) {
        let result = OperationResult.success(result)
        dispatch(result: result)
    }

    private func dispatch(_ error: StorageError) {
        let result = OperationResult.failure(error)
        dispatch(result: result)
    }
}
