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

protocol StorageRemoveTask: AmplifyTaskExecution where Request == AWSS3DeleteObjectRequest, Success == String, Failure == StorageError {}

class AWSS3StorageRemoveTask: StorageRemoveTask, DefaultLogger {

    let request: StorageRemoveRequest
    let storageConfiguration: AWSS3StoragePluginConfiguration
    let storageBehaviour: AWSS3StorageServiceBehavior

    init(_ request: StorageRemoveRequest,
         storageConfiguration: AWSS3StoragePluginConfiguration,
         storageBehaviour: AWSS3StorageServiceBehavior) {
        self.request = request
        self.storageConfiguration = storageConfiguration
        self.storageBehaviour = storageBehaviour
    }

    var eventName: HubPayloadEventName {
        HubPayload.EventName.Storage.remove
    }

    var eventNameCategoryType: CategoryType {
        .storage
    }

    func execute() async throws -> String {
        guard let serviceKey = try await request.path?.resolvePath() else {
            throw StorageError.validation(
                "path",
                "`path` is required for removing an object",
                "Make sure that a valid `path` is passed for removing an object")
        }
        let input = DeleteObjectInput(
            bucket: storageBehaviour.bucket,
            key: serviceKey)
        do {
            _ = try await storageBehaviour.client.deleteObject(input: input)
        } catch let error as StorageErrorConvertible {
            throw error.storageError
        } catch let error {
            throw StorageError.service(
                "Service error occurred.",
                "Please inspect the underlying error for more details.",
                error)
        }
        return serviceKey
    }
}
