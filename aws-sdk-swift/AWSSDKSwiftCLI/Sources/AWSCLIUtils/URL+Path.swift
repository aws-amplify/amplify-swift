//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

@_disfavoredOverload
public func urlPath(_ url: URL?) -> String? {
    guard let url else { return nil }
    return urlPath(url)
}

public func urlPath(_ url: URL) -> String {
    #if os(Linux)
    return url.path
    #else
    return url.path()
    #endif
}
