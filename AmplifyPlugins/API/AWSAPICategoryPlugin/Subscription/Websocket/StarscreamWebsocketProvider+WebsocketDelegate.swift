//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Starscream
import Amplify

/// Extension to handle delegate callback from Starscream
extension StarscreamWebsocketProvider: Starscream.WebSocketDelegate {

    func websocketDidConnect(socket: WebSocketClient) {
        Amplify.API.log.verbose("WebsocketDidConnect")
        listener?(.connect)
    }

    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        Amplify.API.log.verbose("WebsocketDidDisconnect - \(error?.localizedDescription ?? "No error")")
        listener?(.disconnect(error: error))
    }

    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        Amplify.API.log.verbose("WebsocketDidReceiveMessage - \(text)")
        let data = text.data(using: .utf8) ?? Data()

        do {
            let response = try JSONDecoder().decode(WebsocketProviderResponse.self, from: data)
            listener?(.data(response))
        } catch {
            listener?(.error(error))
        }
    }

    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        Amplify.API.log.verbose("WebsocketDidReceiveData - \(data)")
        do {
            let response = try JSONDecoder().decode(WebsocketProviderResponse.self, from: data)
            listener?(.data(response))
        } catch {
            listener?(.error(error))
        }
    }
}
