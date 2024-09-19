//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation

@_spi(WebSocket)
public protocol WebSocketInterceptor {
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
