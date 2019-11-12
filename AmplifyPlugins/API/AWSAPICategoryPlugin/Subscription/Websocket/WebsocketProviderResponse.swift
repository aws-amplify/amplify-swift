//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

struct WebsocketProviderResponse: Decodable {

    let identifier: String?

    let payload: [String: JSONValue]?

    let responseType: WebsocketProviderResponseType

    enum CodingKeys: String, CodingKey {
        case identifier = "id"
        case payload
        case responseType = "type"
    }
}

/// Response types
enum WebsocketProviderResponseType: String, Decodable {

    case connectionAck = "connection_ack"

    case subscriptionAck = "start_ack"

    case unsubscriptionAck = "complete"

    case keepAlive = "ka"

    case data

    case error
}
