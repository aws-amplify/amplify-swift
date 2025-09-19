//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime
import Foundation
import SmithyHTTPAPI

@_spi(PluginHTTPClientEngine)
public func baseClientEngine(
    for configuration: ClientRuntime.DefaultHttpClientConfiguration
) -> HTTPClient {
    return FoundationClientEngine()
}
