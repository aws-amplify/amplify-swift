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

protocol StorageRemoveTask: AmplifySimpleTask where Request == AWSS3DeleteObjectRequest, Success == Void, Failure == StorageError {}

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

    func execute() async throws {
        let serviceKey = request.key
        let input = DeleteObjectInput(
            bucket: storageBehaviour.bucket,
            key: serviceKey)
        _ = try await storageBehaviour.client.deleteObject(input: input)
    }
}
