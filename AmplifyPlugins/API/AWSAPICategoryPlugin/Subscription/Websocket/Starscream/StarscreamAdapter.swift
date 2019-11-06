//
// Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
// Licensed under the Amazon Software License
// http://aws.amazon.com/asl/
//

import Foundation
import Starscream

class StarscreamAdapter: AppSyncWebsocketProvider {

    var socket: WebSocket?
    weak var delegate: AppSyncWebsocketDelegate?

    func connect(url: URL, protocols: [String], delegate: AppSyncWebsocketDelegate?) {
        print("Connecting to url ...")
        socket = WebSocket(url: url, protocols: protocols)
        self.delegate = delegate
        socket?.delegate = self
        socket?.connect()
    }

    func disconnect() {
        socket?.disconnect()
    }

    func write(message: String) {
        print("Websocket write - \(message)")
        socket?.write(string: message)
    }

    var isConnected: Bool {
        return socket?.isConnected ?? false
    }
}
