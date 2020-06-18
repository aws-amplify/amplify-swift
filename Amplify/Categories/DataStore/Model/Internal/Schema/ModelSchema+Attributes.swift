//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Note that although this is public, it is intended for internal use and not consumed directly by host applications.
/// Convenience getters for attributes
public extension ModelSchema {

    var isSyncable: Bool {
        !attributes.contains(.isSystem)
    }

    var isSystem: Bool {
        attributes.contains(.isSystem)
    }

    var hasAuthenticationRules: Bool {
        return !authRules.isEmpty
    }
}
