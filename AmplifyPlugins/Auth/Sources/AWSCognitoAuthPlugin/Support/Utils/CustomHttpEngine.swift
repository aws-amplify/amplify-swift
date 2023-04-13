//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(InternalCustomHttpEngine) @_spi(InternalAmplifyPluginExtension) import AWSPluginsCore
import ClientRuntime
import Foundation

protocol CustomHttpEngine: HttpClientEngine {
    func setHttpClientEngine(_ httpClientEngine: HttpClientEngine)
}

extension UserAgentSuffixAppender: CustomHttpEngine {}
