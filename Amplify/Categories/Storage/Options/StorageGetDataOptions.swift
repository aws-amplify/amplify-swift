//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// StorageGetDataOptions specifies additional options when getting data.
public struct StorageGetDataOptions {

    // Access level of the storage system.
    public let accessLevel: StorageAccessLevel?

    // Target user to apply the action on.
    public let targetIdentityId: String?

    // Extra plugin specific options.
    public let pluginOptions: Any?

    // TODO: transferAcceleration should be in pluginOptions
    // https://docs.aws.amazon.com/AmazonS3/latest/dev/transfer-acceleration.html
    
    public init(accessLevel: StorageAccessLevel?,
                targetIdentityId: String? = nil,
                pluginOptions: Any? = nil) {
        self.accessLevel = accessLevel
        self.targetIdentityId = targetIdentityId
        self.pluginOptions = pluginOptions
    }
}
