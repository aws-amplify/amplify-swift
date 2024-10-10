//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime
import Foundation

@_spi(PluginHTTPClientEngine)
public extension SdkHttpRequest {
    func updatingUserAgent(with value: String) -> SdkHttpRequest {
        let userAgentKey = "User-Agent"
        var headers = headers
        headers.remove(name: userAgentKey)
        headers.add(name: userAgentKey, value: value)

        let endpoint = ClientRuntime.Endpoint(
            host: endpoint.host,
            path: endpoint.path,
            port: endpoint.port,
            queryItems: endpoint.queryItems,
            protocolType: endpoint.protocolType,
            headers: headers,
            properties: endpoint.properties
        )

        return SdkHttpRequest(
            method: method,
            endpoint: endpoint,
            body: body
        )
    }
}
