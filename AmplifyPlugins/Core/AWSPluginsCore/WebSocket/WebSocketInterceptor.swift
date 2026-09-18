//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// - Note: `Sendable` because the interceptor is stored on the `WebSocketClient` actor and awaited
///   across suspension points while building a connection.
@_spi(WebSocket)
public protocol WebSocketInterceptor: Sendable {
    func interceptConnection(url: URL) async -> URL

    func interceptConnection(request: URLRequest) async -> URLRequest
}

public extension WebSocketInterceptor {

    func interceptConnection(url: URL) async -> URL {
        return url
    }

    func interceptConnection(request: URLRequest) async -> URLRequest {
        return request
    }

}
