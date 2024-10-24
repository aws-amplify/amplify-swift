//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@_spi(InternalHttpEngineProxy) @_spi(InternalAmplifyPluginExtension) import InternalAmplifyCredentials
import SmithyHTTPAPI

protocol HttpClientEngineProxy: HTTPClient {
    var target: HTTPClient? { get set }
}

extension UserAgentSuffixAppender: HttpClientEngineProxy {}
