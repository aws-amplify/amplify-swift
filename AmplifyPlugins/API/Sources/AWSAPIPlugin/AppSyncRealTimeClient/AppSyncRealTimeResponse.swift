//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

struct AppSyncRealTimeResponse {

    let id: String?
    let payload: JSONValue?
    let type: EventType

    enum EventType: String, Codable {
        case connectionAck = "connection_ack"
        case startAck = "start_ack"
        case stopAck = "complete"
        case data
        case error
        case connectionError = "connection_error"
        case keepAlive = "ka"
        case starting
    }
}

extension AppSyncRealTimeResponse: Decodable {
}
