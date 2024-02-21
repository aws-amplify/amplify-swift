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

    /// An example of how a client engine provided by aws-swift-sdk can be overridden
    /// ```
    ///     let baseClientEngine: HTTPClient
    ///     #if os(iOS) || os(macOS)
    ///     // networking goes through default aws sdk engine
    ///     baseClientEngine = configuration.httpClientEngine
    ///     #else
    ///     // The custom client engine from where we want to route requests
    ///     // FoundationClientEngine() was an example used in 2.26.x and before
    ///     baseClientEngine = <your custom client engine>
    ///     #endif
    ///     return baseClientEngine
    /// ```
    ///
    /// Starting aws-sdk-release 0.34.0, base HTTP client has been defaulted to foundation.
    /// Hence, amplify doesn't need an override. So return the httpClientEngine present in the configuration.
    return configuration.httpClientEngine


}
