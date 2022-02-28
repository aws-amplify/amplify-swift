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
public class AWSS3StorageDownloadDataOperation: AmplifyInProcessReportingOperation<
    StorageDownloadDataRequest,
    Progress,
    Data,
    StorageError
>, StorageDownloadDataOperation {

    let storageConfiguration: AWSS3StoragePluginConfiguration
    let storageService: AWSS3StorageServiceBehaviour
    let authService: AWSAuthServiceBehavior

    var storageTaskReference: StorageTaskReference?

    // Serial queue for synchronizing access to `storageTaskReference`.
    private let storageTaskActionQueue = DispatchQueue(label: "com.amazonaws.amplify.StorageTaskActionQueue")

    init(_ request: StorageDownloadDataRequest,
         storageConfiguration: AWSS3StoragePluginConfiguration,
         storageService: AWSS3StorageServiceBehaviour,
         authService: AWSAuthServiceBehavior,
         progressListener: InProcessListener?,
         resultListener: ResultListener?) {

        self.storageConfiguration = storageConfiguration
        self.storageService = storageService
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

        let prefixResolver = storageConfiguration.prefixResolver ??
        StorageAccessLevelAwarePrefixResolver(authService: authService)
        prefixResolver.resolvePrefix(for: request.options.accessLevel,
                                        targetIdentityId: request.options.targetIdentityId) { prefixResolution in
            switch prefixResolution {
            case .success(let prefix):
                let serviceKey = prefix + self.request.key
                self.storageService.download(serviceKey: serviceKey, fileURL: nil) { [weak self] event in
                    self?.onServiceEvent(event: event)
                }
            case .failure(let error):
                self.dispatch(error)
                self.finish()
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
