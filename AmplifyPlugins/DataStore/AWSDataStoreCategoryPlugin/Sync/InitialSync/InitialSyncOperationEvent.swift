//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

//
//  InitialSyncOperationEvent.swift
//  AWSDataStoreCategoryPlugin
//
//  Created by Guo, Rui on 10/8/20.
//  Copyright © 2020 Amazon Web Services. All rights reserved.
//
import Amplify
import AWSPluginsCore

enum InitialSyncOperationEvent {
    case started(modelType: Model.Type, syncType: SyncType)
    case mutationSync(MutationSync<AnyModel>)
    case finished(modelType: Model.Type)
}

enum SyncType {
   case fullSync
   case deltaSync
}
