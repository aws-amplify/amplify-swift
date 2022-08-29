//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

import AWSS3
import Amplify
import AWSPluginsCore

extension AWSS3StoragePlugin {

    /// Retrieve the remote URL for the object from storage.
    ///
    /// - Parameters:
    ///   - key: The unique identifier for the object in storage.
    ///   - options: Parameters to specific plugin behavior
    /// - Returns: requested Get URL
    @discardableResult
    public func getURL(key: String,
                       options: StorageGetURLOperation.Request.Options?) async throws -> URL {
        let options = options ?? StorageGetURLRequest.Options()
        let request = StorageGetURLRequest(key: key, options: options)
        let operation = AWSS3StorageGetURLOperation(request,
                                                    storageConfiguration: storageConfiguration,
                                                    storageService: storageService,
                                                    authService: authService)
        let taskAdapter = AmplifyOperationTaskAdapter(operation: operation)
        queue.addOperation(operation)

        return try await taskAdapter.value
    }

    @discardableResult
    public func remove(key: String,
                options: StorageRemoveOperation.Request.Options?) async throws -> String {
        let options = options ?? StorageRemoveRequest.Options()
        let request = StorageRemoveRequest(key: key, options: options)
        let operation = AWSS3StorageRemoveOperation(request,
                                                    storageConfiguration: storageConfiguration,
                                                    storageService: storageService,
                                                    authService: authService)
        let taskAdapter = AmplifyOperationTaskAdapter(operation: operation)
        queue.addOperation(operation)

        return try await taskAdapter.value
    }

}
