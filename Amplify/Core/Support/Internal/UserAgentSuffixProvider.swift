//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@_spi(InternalAmplifyUserAgent)
public protocol UserAgentSuffixProvider {
    var userAgentSuffix: String { get }
}
