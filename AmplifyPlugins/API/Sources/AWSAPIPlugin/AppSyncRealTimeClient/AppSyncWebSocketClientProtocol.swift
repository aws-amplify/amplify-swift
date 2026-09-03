//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
@preconcurrency import Combine
import Foundation
@_spi(WebSocket) import AWSPluginsCore

/// - Note: `Sendable` because the real-time client is an actor that holds this and drives it from
///   detached tasks and nonisolated delegate callbacks.
protocol AppSyncWebSocketClientProtocol: AnyObject, Sendable {
    var isConnected: Bool { get async }
    var publisher: AnyPublisher<WebSocketEvent, Never> { get async }

    func connect(
        autoConnectOnNetworkStatusChange: Bool,
        autoRetryOnConnectionFailure: Bool
    ) async

    func disconnect() async

    func write(message: String) async throws
}

extension WebSocketClient: AppSyncWebSocketClientProtocol { }

