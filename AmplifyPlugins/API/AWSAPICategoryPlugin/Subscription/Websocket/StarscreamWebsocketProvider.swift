//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Starscream
import Amplify

class StarscreamWebsocketProvider: WebsocketProvider {

    let url: URL
    let protocols: [String]
    let request: AppSyncConnectionRequest

    var connectionInterceptors: [ConnectionInterceptor] = []
    var socket: WebSocket?
    var listener: WebsocketEventHandler?

    init(url: URL, protocols: [String] = ["graphql-ws"]) {
        self.url = url
        self.protocols = protocols
        self.request = AppSyncConnectionRequest(url: url)
    }

    deinit {
        socket?.disconnect()
        socket = nil
        connectionInterceptors = []
    }

    func connect() {
        Amplify.API.log.verbose("Connecting to url ...")
        let signedRequest = interceptConnection(request, for: url)
        socket = WebSocket(url: signedRequest.url, protocols: protocols)
        socket?.delegate = self
        socket?.connect()
    }

    func disconnect() {
        socket?.disconnect()
    }

    func write(_ message: String) {
        Amplify.API.log.verbose("Websocket write - \(message)")
        socket?.write(string: message)
    }

    var isConnected: Bool {
        return socket?.isConnected ?? false
    }

    func setListener(_ callback: @escaping WebsocketEventHandler) {
        listener = callback
    }
}
