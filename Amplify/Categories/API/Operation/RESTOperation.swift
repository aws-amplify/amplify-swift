//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// All HTTP operations have the same underlying Operation type
public protocol RESTOperation: AmplifyOperation<RESTOperationRequest, Data, APIError> { }

/// Event names for HubPayloads emitted by this operation
public extension HubPayload.EventName.API {

    /// <#Description#>
    static let delete = "API.delete"

    /// <#Description#>
    static let get = "API.get"

    /// <#Description#>
    static let patch = "API.patch"

    /// <#Description#>
    static let post = "API.post"

    /// <#Description#>
    static let put = "API.put"

    /// <#Description#>
    static let head = "API.head"
}
