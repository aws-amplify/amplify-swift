//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Combine
import Foundation

/// - Note: `Sendable` because the monitor is held by the `WebSocketClient` actor and reached from
///   nonisolated delegate callbacks, so it already crosses concurrency domains.
@_spi(WebSocket)
public protocol WebSocketNetworkMonitorProtocol: Sendable {
    var publisher: AnyPublisher<(AmplifyNetworkMonitor.State, AmplifyNetworkMonitor.State), Never> { get }
    func updateState(_ nextState: AmplifyNetworkMonitor.State) async
}

extension AmplifyNetworkMonitor: WebSocketNetworkMonitorProtocol { }
