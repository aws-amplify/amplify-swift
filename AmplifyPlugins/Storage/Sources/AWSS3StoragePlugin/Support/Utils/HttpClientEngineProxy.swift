//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime
import Foundation

/// Internal protocol that may be to inspect or decorate
/// [ClientRuntime requests](x-source-tag://SdkHttpRequest).
///
/// NOTE: This protocol exists in other categories such as **Auth** and used by higher-level modules via
/// the `@_spi(InternalAmplifyPluginExtension)`. At the time of this writing, no usage outside
/// the AWSS3StoragePlugin is necessary so this protocol is not exposed via the SPI.
///
/// See:
/// 
/// * [URLRequestDelegate](x-source-tag://URLRequestDelegate)
/// * [CommonRuntime.HttpClientEngine](x-source-tag://HttpClientEngine)
///
/// - Tag: HttpClientEngineProxy
protocol HttpClientEngineProxy: HttpClientEngine {

    /// The actual engine performing the requests. This must be set before the receiver gets its first call to
    /// `execute(request:)`.
    ///
    /// - Tag: HttpClientEngineProxy.target
    var target: HttpClientEngine? { get set }
}
