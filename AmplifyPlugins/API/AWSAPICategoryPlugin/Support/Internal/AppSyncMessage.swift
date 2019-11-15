//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Struct that holds the message to be send to the connection
struct AppSyncMessage {

    /// Identifier for the message.
    ///
    /// This value is not required for all messages. Message of type
    /// .subscribe and .unsubscribe should have an identifier.
    let id: String?

    /// Payload for the websocket message. This is not a required field.
    let payload: Payload?

    /// Message type
    let messageType: AppSyncMessageType

    init(id: String? = nil,
         payload: Payload? = nil,
         type: AppSyncMessageType) {
        self.id = id
        self.payload = payload
        self.messageType = type
    }

    struct Payload {
        var data: String?
        var authHeader: AuthenticationHeader?
    }
}

class AuthenticationHeader: Encodable {
    let host: String?

    init(host: String) {
        self.host = host
    }
}

/// Message types
enum AppSyncMessageType: String {

    case connectionInit = "connection_init"

    case subscribe = "start"

    case unsubscribe = "stop"

    func getValue() -> String {
        return rawValue
    }
}
