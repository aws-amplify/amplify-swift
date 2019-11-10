//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
import Starscream

/// Extension to handle delegate callback from Starscream
extension StarscreamAdapter: Starscream.WebSocketDelegate {

    func websocketDidConnect(socket: WebSocketClient) {
        print("WebsocketDidConnect")
        delegate?.websocketDidConnect(provider: self)
    }

    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        print("WebsocketDidDisconnect - \(error?.localizedDescription ?? "No error")")
        delegate?.websocketDidDisconnect(provider: self, error: error)
    }

    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        print("WebsocketDidReceiveMessage - \(text)")
        let data = text.data(using: .utf8) ?? Data()
        delegate?.websocketDidReceiveData(provider: self, data: data)
    }

    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        print("WebsocketDidReceiveData - \(data)")
        delegate?.websocketDidReceiveData(provider: self, data: data)
    }
}
