//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AppSyncResponse {

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
