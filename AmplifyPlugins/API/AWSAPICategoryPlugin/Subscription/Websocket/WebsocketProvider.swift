//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Protocol to be implemented by different websocket providers
protocol WebsocketProvider {

    typealias WebsocketEventHandler = (WebsocketEvent) -> Void

    /// Initiates a connection to the given url.
    ///
    /// This is an async call. After the connection is succesfully established, the delegate
    /// will receive the callback on `websocketDidConnect(:)`
    func connect()

    /// Disconnects the websocket.
    func disconnect()

    /// Write message to the websocket provider
    /// - Parameter message: Message to write
    func write(_ message: String)

    /// Returns `true` if the websocket is connected
    var isConnected: Bool { get }

    func setListener(_ callback: @escaping WebsocketEventHandler)
}

enum WebsocketEvent {
    case connect

    case disconnect(error: Error?)

    case data(WebsocketProviderResponse)

    case error(Error)
}
