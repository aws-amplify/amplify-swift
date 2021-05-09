//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Convenience getters for attributes
public extension ModelSchema {

    /// <#Description#>
    var isSyncable: Bool {
        !attributes.contains(.isSystem)
    }

    /// <#Description#>
    var isSystem: Bool {
        attributes.contains(.isSystem)
    }

    /// <#Description#>
    var hasAuthenticationRules: Bool {
        return !authRules.isEmpty
    }
}
