//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Struct that holds the message to be send to the connection
public struct AppSyncMessage {

    /// Identifier for the message.
    ///
    /// This value is not required for all messages. Message of type
    /// .subscribe and .unsubscribe should have an identifier.
    public let id: String?

    /// Payload for the websocket message. This is not a required field.
    public let payload: Payload?

    /// Message type
    public let messageType: AppSyncMessageType

    public init(id: String? = nil,
         payload: Payload? = nil,
         type: AppSyncMessageType) {
        self.id = id
        self.payload = payload
        self.messageType = type
    }

    public struct Payload {
        public init(data: String? = nil, authHeader: AuthenticationHeader? = nil) {
            self.data = data
            self.authHeader = authHeader
        }

        public var data: String?
        public var authHeader: AuthenticationHeader?
    }
}

open class AuthenticationHeader: Encodable {
    let host: String?

    public init(host: String) {
        self.host = host
    }
}

/// Message types
public enum AppSyncMessageType {

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
