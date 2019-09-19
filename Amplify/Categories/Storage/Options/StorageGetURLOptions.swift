//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// StorageGetURLOptions specifies additional options when retrieving the remote URL.
public struct StorageGetURLOptions {

    // Access level of the storage system.
    public let accessLevel: StorageAccessLevel?

    // Target user to apply the action on.
    public let targetIdentityId: String?

    // Number of seconds before the URL expires.
    public let expires: Int?

    // Extra plugin specific options.
    public let pluginOptions: Any?

    public init(accessLevel: StorageAccessLevel?,
                targetIdentityId: String? = nil,
                expires: Int? = nil,
                pluginOptions: Any? = nil) {
        self.accessLevel = accessLevel
        self.targetIdentityId = targetIdentityId
        self.expires = expires
        self.pluginOptions = pluginOptions
    }
}
