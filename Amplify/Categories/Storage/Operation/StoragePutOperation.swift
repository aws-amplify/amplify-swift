//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public typealias StoragePutDataOperation = StoragePutOperation
public typealias StorageUploadFileOperation = StoragePutOperation

import Foundation

public protocol StoragePutOperation: AmplifyOperation<Progress, String, StorageError> {

}
