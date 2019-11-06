//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
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
enum AppSyncMessageType {

    case connectionInit(String)

    case subscribe(String)

    case unsubscribe(String)

    func getValue() -> String {
        switch self {
        case .connectionInit(let value):
            return value
        case .subscribe(let value):
            return value
        case .unsubscribe(let value):
            return value
        }
    }
}
