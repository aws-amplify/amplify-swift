//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// <#Description#>
public struct AuthCategoryConfiguration: CategoryConfiguration {

    /// <#Description#>
    public var plugins: [String: JSONValue]

    /// <#Description#>
    /// - Parameter plugins: <#plugins description#>
    public init(plugins: [String: JSONValue] = [:]) {
        self.plugins = plugins
    }
}
