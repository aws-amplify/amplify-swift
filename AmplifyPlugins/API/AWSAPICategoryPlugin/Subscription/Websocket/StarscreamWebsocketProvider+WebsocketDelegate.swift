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
        listener?(.connect)
    }

    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        print("WebsocketDidDisconnect - \(error?.localizedDescription ?? "No error")")
        listener?(.disconnect(error: error))
    }

    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        print("WebsocketDidReceiveMessage - \(text)")
        let data = text.data(using: .utf8) ?? Data()

        do {
            let response = try JSONDecoder().decode(WebsocketProviderResponse.self, from: data)
            listener?(.data(response))
        } catch {
            print(error)
            //listener?(.error(nil, ConnectionProviderError.jsonParse(nil, error)))
            // we used to send error on listener, now what?
        }
    }

    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        print("WebsocketDidReceiveData - \(data)")
        do {
            let response = try JSONDecoder().decode(WebsocketProviderResponse.self, from: data)
            listener?(.data(response))
        } catch {
            print(error)
            //listener?(.error(nil, ConnectionProviderError.jsonParse(nil, error)))
            // we used to send error on listener, now what?
        }
    }
}
