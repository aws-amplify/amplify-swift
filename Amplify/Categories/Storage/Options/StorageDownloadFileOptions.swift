//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// StorageDownloadFileOptions specifies additional options when downloading the file.
public struct StorageDownloadFileOptions {

    // Access level of the storage system.
    public let accessLevel: StorageAccessLevel?

    // Target user to apply the action on.
    public let targetIdentityId: String?

    // Extra plugin specific options.
    public let pluginOptions: Any?

    public init(accessLevel: StorageAccessLevel?,
                targetIdentityId: String? = nil,
                pluginOptions: Any? = nil) {
        self.accessLevel = accessLevel
        self.targetIdentityId = targetIdentityId
        self.pluginOptions = pluginOptions
    }
}
