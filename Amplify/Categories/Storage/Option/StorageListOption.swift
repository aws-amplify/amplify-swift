//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct StorageListOption {
    public var accessLevel: StorageAccessLevel?

    public var targetIdentityId: String?

    public var path: String?

    public var limit: Int?

    public var options: Any?

    public init(accessLevel: StorageAccessLevel?,
                targetIdentityId: String?,
                path: String?,
                limit: Int?,
                options: Any?) {
        self.accessLevel = accessLevel
        self.targetIdentityId = targetIdentityId
        self.options = options
        self.path = path
        self.limit = limit
    }
}
