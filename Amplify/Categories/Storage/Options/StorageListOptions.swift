//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct StorageListOptions {
    public var accessLevel: StorageAccessLevel?

    public var targetIdentityId: String?

    public var path: String?

    public var options: Any?

    public init(accessLevel: StorageAccessLevel?,
                targetIdentityId: String? = nil,
                path: String? = nil,
                options: Any? = nil) {
        self.accessLevel = accessLevel
        self.targetIdentityId = targetIdentityId
        self.options = options
        self.path = path
    }
}
