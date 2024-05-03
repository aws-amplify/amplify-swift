//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import ClientRuntime
import AWSClientRuntime

@_spi(PluginHTTPClientEngine)
public func baseClientEngine(
    for configuration: AWSClientConfiguration<some AWSServiceSpecificConfiguration>
) -> HTTPClient {
    let baseClientEngine: HTTPClient
    
    #if os(macOS)
    // networking goes through CRT
    baseClientEngine = configuration.httpClientEngine
    #else
    // networking goes through Foundation
    baseClientEngine = FoundationClientEngine()
    #endif
    return baseClientEngine
}
