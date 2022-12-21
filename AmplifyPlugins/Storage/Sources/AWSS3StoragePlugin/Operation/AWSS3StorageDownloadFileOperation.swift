//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

// TODO: thread safety: everything has to be locked down
// TODO verify no retain cycle

/// Storage Download File Operation.
///
/// See: [Operations] for more details.
///
/// [Operations]: https://github.com/aws-amplify/amplify-ios/blob/main/OPERATIONS.md
class AWSS3StorageDownloadFileOperation: AmplifyInProcessReportingOperation<
    StorageDownloadFileRequest,
    Progress,
    Void,
    StorageError
>, StorageDownloadFileOperation {

    let storageConfiguration: AWSS3StoragePluginConfiguration
    let storageService: AWSS3StorageServiceBehaviour
    let authService: AWSAuthServiceBehavior

    var storageTaskReference: StorageTaskReference?

    // Serial queue for synchronizing access to `storageTaskReference`.
    private let storageTaskActionQueue = DispatchQueue(label: "com.amazonaws.amplify.StorageTaskActionQueue")

    init(_ request: StorageDownloadFileRequest,
         storageConfiguration: AWSS3StoragePluginConfiguration,
         storageService: AWSS3StorageServiceBehaviour,
         authService: AWSAuthServiceBehavior,
         progressListener: InProcessListener? = nil,
         resultListener: ResultListener? = nil) {

        self.storageConfiguration = storageConfiguration
        self.storageService = storageService
        self.authService = authService
        super.init(categoryType: .storage,
                   eventName: HubPayload.EventName.Storage.downloadFile,
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

    /// Performs the task to download file.
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
                let serviceKey = prefix + request.key
                let accelerate = try AWSS3PluginOptions.accelerateValue(pluginOptions: request.options.pluginOptions)
                storageService.download(serviceKey: serviceKey, fileURL: self.request.local, accelerate: accelerate) { [weak self] event in
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
        case .completed:
            dispatch()
            finish()
        case .failed(let error):
            dispatch(error)
            finish()
        }
    }

    private func dispatch(_ progress: Progress) {
        dispatchInProcess(data: progress)
    }

    private func dispatch() {
        let result = OperationResult.successfulVoid
        dispatch(result: result)
    }

    private func dispatch(_ error: StorageError) {
        let result = OperationResult.failure(error)
        dispatch(result: result)
    }
}
