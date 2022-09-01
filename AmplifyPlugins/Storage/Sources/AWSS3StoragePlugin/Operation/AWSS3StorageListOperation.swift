//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

/// Strorage List Operation.
///
/// See: [Operations] for more details.
///
/// [Operations]: https://github.com/aws-amplify/amplify-ios/blob/main/OPERATIONS.md
public class AWSS3StorageListOperation: AmplifyOperation<
    StorageListRequest,
    StorageListResult,
    StorageError
>, StorageListOperation {

    let storageConfiguration: AWSS3StoragePluginConfiguration
    let storageService: AWSS3StorageServiceBehaviour
    let authService: AWSAuthServiceBehavior

    init(_ request: StorageListRequest,
         storageConfiguration: AWSS3StoragePluginConfiguration,
         storageService: AWSS3StorageServiceBehaviour,
         authService: AWSAuthServiceBehavior,
         resultListener: ResultListener? = nil) {

        self.storageConfiguration = storageConfiguration
        self.storageService = storageService
        self.authService = authService
        super.init(categoryType: .storage,
                   eventName: HubPayload.EventName.Storage.list,
                   request: request,
                   resultListener: resultListener)
    }

    /// Cancels operation.
    override public func cancel() {
        super.cancel()
    }

    /// Performs the task to get list.
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
                let prefix = try await prefixResolver.resolvePrefix(for: request.options.accessLevel, targetIdentityId: request.options.targetIdentityId)
                storageService.list(prefix: prefix, path: request.options.path) { [weak self] event in
                    self?.onServiceEvent(event: event)
                }
            } catch {
                dispatch(StorageError(error: error))
                finish()
            }
        }
    }

    private func onServiceEvent(event: StorageEvent<Void, Void, StorageListResult, StorageError>) {
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

    private func dispatch(_ result: StorageListResult) {
        let result = OperationResult.success(result)
        dispatch(result: result)
    }

    private func dispatch(_ error: StorageError) {
        let result = OperationResult.failure(error)
        dispatch(result: result)
    }
}
