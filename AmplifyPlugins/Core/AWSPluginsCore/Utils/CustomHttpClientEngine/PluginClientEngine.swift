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
    return FoundationClientEngine()
}
