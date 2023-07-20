//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(InternalHttpEngineProxy) @_spi(InternalAmplifyPluginExtension) import AWSPluginsCore
import ClientRuntime
import Foundation

protocol HttpClientEngineProxy: HttpClientEngine {
    var target: HttpClientEngine? { set get }
}

extension UserAgentSuffixAppender: HttpClientEngineProxy {}
