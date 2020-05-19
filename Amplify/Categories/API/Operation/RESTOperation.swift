//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// All HTTP operations have the same underlying Operation type
public protocol RESTOperation: AmplifyOperation<RESTOperationRequest, Data, APIError> { }

/// Event names for HubPayloads emitted by this operation
public extension HubPayload.EventName.API {
    static let delete = "API.delete"
    static let get = "API.get"
    static let patch = "API.patch"
    static let post = "API.post"
    static let put = "API.put"
    static let head = "API.head"
}
