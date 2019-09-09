//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct StorageGetOption {

    // AccessLevel
    public var accessLevel: StorageAccessLevel?

    // Specifics the user when retrieving data
    public let targetIdentityId: String?

    //
    public let storageGetDestination: StorageGetDestination

    // Extra options
    public var options: Any?

    public init(accessLevel: StorageAccessLevel? = nil,
                targetIdentityId: String? = nil,
                storageGetDestination: StorageGetDestination? = nil,
                options: Any? = nil) {
        self.accessLevel = accessLevel
        self.targetIdentityId = targetIdentityId
        self.storageGetDestination = storageGetDestination ?? .url(expires: nil)
        self.options = options
    }
}
