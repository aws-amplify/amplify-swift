//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime
import Foundation
@_spi(InternalHttpEngineProxy) @_spi(InternalAmplifyPluginExtension) import InternalAmplifyCredentials

protocol HttpClientEngineProxy: HTTPClient {
    var target: HTTPClient? { get set }
}

extension UserAgentSuffixAppender: HttpClientEngineProxy {}
