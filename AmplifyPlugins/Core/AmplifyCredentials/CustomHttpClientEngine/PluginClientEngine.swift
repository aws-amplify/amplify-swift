//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import ClientRuntime
import SmithyHTTPAPI

@_spi(PluginHTTPClientEngine)
public func baseClientEngine(
    for configuration: ClientRuntime.DefaultHttpClientConfiguration
) -> HTTPClient {
    return FoundationClientEngine()
}
