//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

typealias ConnectionProviderCallback = (ConnectionProviderEvent) -> Void

protocol ConnectionProvider: class {

    func connect()

    func disconnect()

    func subscribe(_ subscriptionItem: SubscriptionItem)

    func unsubscribe(_ identifier: String)

    var isConnected: Bool { get }

    func setListener(_ callback: @escaping ConnectionProviderCallback)
}

enum ConnectionProviderEvent {

    case connection(ConnectionState)

    /// Keep alive ping from the service
    case keepAlive

    /// Subscription has been connected to the connection
    case subscriptionConnected(identifier: String)

    /// Subscription has been disconnected from the connection
    case subscriptionDisconnected(identifier: String)

    /// Data received on the connection
    case data(identifier: String, payload: [String: JSONValue])

    /// Subscription related error event
    case subscriptionError(String, ConnectionProviderError)

    /// Error event
    case error(ConnectionProviderError)
}

/// Synchronized to the state of the underlying websocket connection
enum ConnectionState {
    /// The websocket connection was created
    case connecting

    /// The websocket connection has been established
    case connected

    /// The websocket connection has been disconnected
    case disconnected(error: ConnectionProviderError?)
}
