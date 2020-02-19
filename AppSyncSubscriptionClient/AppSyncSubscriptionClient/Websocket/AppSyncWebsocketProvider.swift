//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Protocol to be implemented by different websocket providers
public protocol AppSyncWebsocketProvider {

    /// Initiates a connection to the given url.
    ///
    /// This is an async call. After the connection is succesfully established, the delegate
    /// will receive the callback on `websocketDidConnect(:)`
    func connect(url: URL, protocols: [String], delegate: AppSyncWebsocketDelegate?)

    /// Disconnects the websocket.
    func disconnect()

    /// Write message to the websocket provider
    /// - Parameter message: Message to write
    func write(message: String)

    /// Returns `true` if the websocket is connected
    var isConnected: Bool { get }
}

/// Delegate method to get callbacks on websocket provider connection
public protocol AppSyncWebsocketDelegate: class {

    func websocketDidConnect(provider: AppSyncWebsocketProvider)

    func websocketDidDisconnect(provider: AppSyncWebsocketProvider, error: Error?)

    func websocketDidReceiveData(provider: AppSyncWebsocketProvider, data: Data)
}
