//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import AWSPluginsCore

/// Upload Data Operation.
///
/// See: [Operations] for more details.
///
/// [Operations]: https://github.com/aws-amplify/amplify-ios/blob/main/OPERATIONS.md
class AWSS3StorageUploadDataOperation: AmplifyInProcessReportingOperation<
    StorageUploadDataRequest,
    Progress,
    String,
    StorageError
>, StorageUploadDataOperation {

    let storageConfiguration: AWSS3StoragePluginConfiguration
    let storageServiceProvider: AWSS3StorageServiceProvider
    let authService: AWSAuthServiceBehavior

    var storageTaskReference: StorageTaskReference?
    private var resolvedPath: String?
    /// Serial queue for synchronizing access to `storageTaskReference`.
    private let storageTaskActionQueue = DispatchQueue(label: "com.amazonaws.amplify.StorageTaskActionQueue")

    private var storageService: AWSS3StorageServiceBehavior {
        get throws {
            return try storageServiceProvider()
        }
    }

    init(_ request: StorageUploadDataRequest,
         storageConfiguration: AWSS3StoragePluginConfiguration,
         storageServiceProvider: @escaping AWSS3StorageServiceProvider,
         authService: AWSAuthServiceBehavior,
         progressListener: InProcessListener? = nil,
         resultListener: ResultListener? = nil) {

        self.storageConfiguration = storageConfiguration
        self.storageServiceProvider = storageServiceProvider
        self.authService = authService
        super.init(categoryType: .storage,
                   eventName: HubPayload.EventName.Storage.uploadData,
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

    /// Resume operation.
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

    /// Performs the task to upload data.
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
                    resolvedPath = serviceKey
                } else {
                    let prefixResolver = storageConfiguration.prefixResolver ??
                    StorageAccessLevelAwarePrefixResolver(authService: authService)
                    let prefix = try await prefixResolver.resolvePrefix(for: request.options.accessLevel, targetIdentityId: request.options.targetIdentityId)
                    serviceKey = prefix + request.key
                }

                let accelerate = try AWSS3PluginOptions.accelerateValue(pluginOptions: request.options.pluginOptions)
                if request.data.count > StorageUploadDataRequest.Options.multiPartUploadSizeThreshold {
                    try storageService.multiPartUpload(
                        serviceKey: serviceKey,
                        uploadSource: .data(request.data),
                        contentType: request.options.contentType,
                        metadata: request.options.metadata,
                        accelerate: accelerate
                    ) { [weak self] event in
                        self?.onServiceEvent(event: event)
                    }
                } else {
                    try storageService.upload(
                        serviceKey: serviceKey,
                        uploadSource: .data(request.data),
                        contentType: request.options.contentType,
                        metadata: request.options.metadata,
                        accelerate: accelerate
                    ) { [weak self] event in
                        self?.onServiceEvent(event: event)
                    }
                }
            } catch {
                dispatch(StorageError(error: error))
                finish()
            }
        }
    }

    private func onServiceEvent(
        event: StorageEvent<StorageTaskReference, Progress, Void, StorageError>) {
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
            if let path = resolvedPath {
                dispatch(path)
            } else {
                dispatch(request.key)
            }
            finish()
        case .failed(let error):
            dispatch(error)
            finish()
        }
    }

    private func dispatch(_ progress: Progress) {
        dispatchInProcess(data: progress)
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
