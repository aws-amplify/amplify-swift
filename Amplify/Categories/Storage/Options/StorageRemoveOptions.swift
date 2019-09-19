//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// StorageRemoveOptions specifies additional options when removing an object from storage.
public struct StorageRemoveOptions {

    // Access level of the storage system.
    public let accessLevel: StorageAccessLevel?

    // Extra plugin specific options
    public let pluginOptions: Any?

    public init(accessLevel: StorageAccessLevel?, pluginOptions: Any? = nil) {
        self.accessLevel = accessLevel
        self.pluginOptions = pluginOptions
    }
}
