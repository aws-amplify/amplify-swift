//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Starscream

public class StarscreamAdapter: AppSyncWebsocketProvider {

    public init() {
    }

    var socket: WebSocket?
    weak var delegate: AppSyncWebsocketDelegate?

    public func connect(url: URL, protocols: [String], delegate: AppSyncWebsocketDelegate?) {
        AppSyncLogger.verbose("Connecting to url ...")
        socket = WebSocket(url: url, protocols: protocols)
        self.delegate = delegate
        socket?.delegate = self
        socket?.connect()
    }

    public func disconnect() {
        socket?.disconnect()
    }

    public func write(message: String) {
        AppSyncLogger.verbose("Websocket write - \(message)")
        socket?.write(string: message)
    }

    public var isConnected: Bool {
        return socket?.isConnected ?? false
    }
}
