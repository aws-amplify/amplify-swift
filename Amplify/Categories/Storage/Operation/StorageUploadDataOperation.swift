//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol StorageUploadDataOperation: AmplifyInProcessReportingOperation<
    StorageUploadDataRequest,
    Progress,
    String,
    StorageError
> {}

public extension HubPayload.EventName.Storage {
    /// eventName for HubPayloads emitted by this operation
    static let uploadData = "Storage.uploadData"
}

public typealias StorageUploadDataTask = AmplifyInProcessReportingOperationTaskAdapter<StorageUploadDataRequest,
                                                                                       Progress,
                                                                                       String,
                                                                                       StorageError>
