//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Convenience getters for attributes
public extension ModelSchema {

    var isSyncable: Bool {
        !attributes.contains(.isSystem)
    }

    var isSystem: Bool {
        attributes.contains(.isSystem)
    }

}
