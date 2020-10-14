//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore

enum InitialSyncOperationEvent {
    /// This event is used to notify `ModelSyncedEventEmitter` the `SyncType` of `ModelType`
    case started(modelType: Model.Type, syncType: SyncType)
    /// Each time an item is enqueued into `ReconciliationAndLocalSaveOperationQueue`, send the event
    /// to `ModelSyncedEventEmitter` to let it do the `recordReceived` incrementing.
    case enqueued(MutationSync<AnyModel>)
    /// `finished` value is used to notify `ModelSyncedEventEmitter` that the `InitialSyncOperation`
    /// of `ModelType` has finished offering items to `ReconciliationAndLocalSaveOperationQueue`
    case finished(modelType: Model.Type)
}

enum SyncType {
   case fullSync
   case deltaSync
}
