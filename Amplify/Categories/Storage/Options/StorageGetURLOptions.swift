//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct StorageGetURLOptions {

    public var accessLevel: StorageAccessLevel?

    public let targetIdentityId: String?

    public let expires: Int?

    public var options: Any?

    public init(accessLevel: StorageAccessLevel? = nil,
                targetIdentityId: String? = nil,
                expires: Int? = nil,
                options: Any? = nil) {
        self.accessLevel = accessLevel
        self.targetIdentityId = targetIdentityId
        self.expires = expires
        self.options = options
    }
}
