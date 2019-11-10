//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
import Starscream

/// Extension to handle delegate callback from Starscream
extension StarscreamWebsocketProvider: Starscream.WebSocketDelegate {

    func websocketDidConnect(socket: WebSocketClient) {
        print("WebsocketDidConnect")
        onEvent(.connect)
    }

    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        print("WebsocketDidDisconnect - \(error?.localizedDescription ?? "No error")")
        onEvent(.disconnect(error: error))
    }

    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        print("WebsocketDidReceiveMessage - \(text)")
        let data = text.data(using: .utf8) ?? Data()
        onEvent(.data(data))
    }

    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        print("WebsocketDidReceiveData - \(data)")
        onEvent(.data(data))
    }
}
