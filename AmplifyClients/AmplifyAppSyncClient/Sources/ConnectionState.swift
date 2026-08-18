//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// The connection state of the client's shared WebSocket.
public enum ConnectionState: Sendable {
    /// A WebSocket connection is being established.
    case connecting
    /// The WebSocket connection is established and ready.
    case connected
    /// No active WebSocket connection.
    /// - Parameter reason: A description of why the connection was lost, or nil for clean shutdown.
    case disconnected(reason: String? = nil)
}
