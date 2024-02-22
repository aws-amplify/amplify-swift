//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(InternalHttpEngineProxy) @_spi(InternalAmplifyPluginExtension) import AWSPluginsCore
import ClientRuntime
import Foundation

protocol HttpClientEngineProxy: HTTPClient {
    var target: HTTPClient? { get set }
}

extension UserAgentSuffixAppender: HttpClientEngineProxy {}
