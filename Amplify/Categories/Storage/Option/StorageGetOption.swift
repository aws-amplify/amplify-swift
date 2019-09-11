//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct StorageGetOption {

    public var accessLevel: StorageAccessLevel?

    public let targetIdentityId: String?

    public let storageGetDestination: StorageGetDestination

    public var options: Any?

    // TODO: transferAcceleration should be in options most likely. and can be set globally
    // https://docs.aws.amazon.com/AmazonS3/latest/dev/transfer-acceleration.html

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
