//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation
import Combine
@_spi(WebSocket) import AWSPluginsCore

protocol AppSyncWebSocketClientProtocol: AnyObject {
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

