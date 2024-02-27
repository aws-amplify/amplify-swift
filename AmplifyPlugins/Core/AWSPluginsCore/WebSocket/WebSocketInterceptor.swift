//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation

@_spi(AmplifySwift)
public protocol WebSocketInterceptor {
    func interceptConnection(url: URL) async -> URL
}