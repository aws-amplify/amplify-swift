//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

/// Storage Download Data Operation.
///
/// See: [Operations] for more details.
///
/// [Operations]: https://github.com/aws-amplify/amplify-ios/blob/main/OPERATIONS.md
class AWSS3StorageDownloadDataOperation: AmplifyInProcessReportingOperation<
    StorageDownloadDataRequest,
    Progress,
    Data,
    StorageError
>, StorageDownloadDataOperation, @unchecked Sendable {

    let storageConfiguration: AWSS3StoragePluginConfiguration
    let storageServiceProvider: AWSS3StorageServiceProvider
    let authService: AWSAuthServiceBehavior

    var storageTaskReference: StorageTaskReference?

    // Serial queue for synchronizing access to `storageTaskReference`.
    private let storageTaskActionQueue = DispatchQueue(label: "com.amazonaws.amplify.StorageTaskActionQueue")

    private var storageService: AWSS3StorageServiceBehavior {
        get throws {
            return try storageServiceProvider()
        }
    }

    init(_ request: StorageDownloadDataRequest,
         storageConfiguration: AWSS3StoragePluginConfiguration,
         storageServiceProvider: @escaping AWSS3StorageServiceProvider,
         authService: AWSAuthServiceBehavior,
         progressListener: InProcessListener? = nil,
         resultListener: ResultListener? = nil) {

        self.storageConfiguration = storageConfiguration
        self.storageServiceProvider = storageServiceProvider
        self.authService = authService
        super.init(categoryType: .storage,
                   eventName: HubPayload.EventName.Storage.downloadData,
                   request: request,
                   inProcessListener: progressListener,
                   resultListener: resultListener)
    }

    /// Pauses operation.
    override public func pause() {
        storageTaskActionQueue.async {
            self.storageTaskReference?.pause()
            super.pause()
        }
    }

    /// Resumes operation.
    override public func resume() {
        storageTaskActionQueue.async {
            self.storageTaskReference?.resume()
            super.resume()
        }
    }

    /// Cancels operation.
    override public func cancel() {
        storageTaskActionQueue.async {
            self.storageTaskReference?.cancel()
            super.cancel()
        }
    }

    /// Performs the task to download data.
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

        Task {
            do {
                let serviceKey: String
                if let path = request.path {
                    serviceKey = try await path.resolvePath(authService: self.authService)
                } else {
                    let prefixResolver = storageConfiguration.prefixResolver ??
                    StorageAccessLevelAwarePrefixResolver(authService: authService)
                    let prefix = try await prefixResolver.resolvePrefix(for: request.options.accessLevel, targetIdentityId: request.options.targetIdentityId)
                    serviceKey = prefix + request.key
                }

                let accelerate = try AWSS3PluginOptions.accelerateValue(pluginOptions: request.options.pluginOptions)
                try storageService.download(serviceKey: serviceKey, fileURL: nil, accelerate: accelerate) { [weak self] event in
                    self?.onServiceEvent(event: event)
                }
            } catch {
                dispatch(StorageError(error: error))
                finish()
            }
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
        dispatchInProcess(data: progress)
    }

    private func dispatch(_ result: Data) {
        let result = OperationResult.success(result)
        dispatch(result: result)
    }

    private func dispatch(_ error: StorageError) {
        let result = OperationResult.failure(error)
        dispatch(result: result)
    }
}
