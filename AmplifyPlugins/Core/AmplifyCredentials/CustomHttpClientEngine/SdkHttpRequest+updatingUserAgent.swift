//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SmithyHTTPAPI

@_spi(PluginHTTPClientEngine)
extension HTTPRequest {
    public func updatingUserAgent(with value: String) -> HTTPRequest {
        let userAgentKey = "User-Agent"
        var headers = headers
        headers.remove(name: userAgentKey)
        headers.add(name: userAgentKey, value: value)

        let endpoint = SmithyHTTPAPI.Endpoint(
            uri: endpoint.uri,
            headers: headers
        )

        return HTTPRequest(
            method: method,
            endpoint: endpoint,
            body: body
        )
    }
}
