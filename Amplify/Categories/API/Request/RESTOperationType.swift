//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The type of API operation
public enum RESTOperationType: String {
    case get = "GET"
    case put = "PUT"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
    case head = "HEAD"
}

extension RESTOperationType: HubPayloadEventNameConvertible {
    public var hubEventName: String {
        switch self {
        case .get:
            return HubPayload.EventName.API.get
        case .put:
            return HubPayload.EventName.API.put
        case .post:
            return HubPayload.EventName.API.post
        case .patch:
            return HubPayload.EventName.API.patch
        case .delete:
            return HubPayload.EventName.API.delete
        case .head:
            return HubPayload.EventName.API.head
        }
    }
}
