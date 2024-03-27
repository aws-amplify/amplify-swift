//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation
import AWSS3
import AWSPluginsCore

protocol StorageGetURLTask: AmplifyTaskExecution where Request == StorageGetURLRequest, Success == URL, Failure == StorageError {}

class AWSS3StorageGetURLTask: StorageGetURLTask, DefaultLogger {

    let request: StorageGetURLRequest
    let storageBehaviour: AWSS3StorageServiceBehavior

    init(_ request: StorageGetURLRequest,
         storageBehaviour: AWSS3StorageServiceBehavior) {
        self.request = request
        self.storageBehaviour = storageBehaviour
    }

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Storage.getURL
    }

    var eventNameCategoryType: CategoryType {
        .storage
    }

    func execute() async throws -> URL {
        guard let serviceKey = try await request.path?.resolvePath() else {
            throw StorageError.validation(
                "path",
                "`path` is required field",
                "Make sure that a valid `path` is passed for removing an object")
        }

        // Validate object if needed
        if let pluginOptions = request.options.pluginOptions as? AWSStorageGetURLOptions, pluginOptions.validateObjectExistence {
            try await storageBehaviour.validateObjectExistence(serviceKey: serviceKey)
        }

        let accelerate = try AWSS3PluginOptions.accelerateValue(
            pluginOptions: request.options.pluginOptions)

        do {
            return try await storageBehaviour.getPreSignedURL(
                serviceKey: serviceKey,
                signingOperation: .getObject,
                metadata: nil,
                accelerate: accelerate,
                expires: request.options.expires
            )
        } catch let error as StorageErrorConvertible {
            throw error.storageError
        } catch let error {
            throw StorageError.service(
                "Service error occurred.",
                "Please inspect the underlying error for more details.",
                error)
        }

    }
}
