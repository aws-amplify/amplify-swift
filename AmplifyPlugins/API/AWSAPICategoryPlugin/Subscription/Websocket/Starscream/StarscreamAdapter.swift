//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Starscream

class StarscreamAdapter: AppSyncWebsocketProvider {

    var socket: WebSocket?
    weak var delegate: AppSyncWebsocketDelegate?

    func connect(url: URL, protocols: [String], delegate: AppSyncWebsocketDelegate?) {
        AppSyncLogger.verbose("Connecting to url ...")
        socket = WebSocket(url: url, protocols: protocols)
        self.delegate = delegate
        socket?.delegate = self
        socket?.connect()
    }

    func disconnect() {
        socket?.disconnect()
    }

    func write(message: String) {
        AppSyncLogger.verbose("Websocket write - \(message)")
        socket?.write(string: message)
    }

    var isConnected: Bool {
        return socket?.isConnected ?? false
    }
}
