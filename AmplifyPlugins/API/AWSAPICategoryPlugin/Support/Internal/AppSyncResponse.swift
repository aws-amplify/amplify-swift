//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
import Amplify

struct AppSyncResponse {

    let id: String?

    let payload: [String: JSONValue]?

    let responseType: AppSyncResponseType

    init(id: String? = nil,
         payload: [String: JSONValue]? = nil,
         type: AppSyncResponseType) {
        self.id = id
        self.responseType = type
        self.payload = payload
    }
}

/// Response types
enum AppSyncResponseType {

    case subscriptionAck

    case unsubscriptionAck

    case data
}
