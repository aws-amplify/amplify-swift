//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation

struct AppSyncResponse {

    let id: String?

    let payload: [String: AppSyncJSONValue]?

    let responseType: AppSyncResponseType

    init(id: String? = nil,
         payload: [String: AppSyncJSONValue]? = nil,
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
