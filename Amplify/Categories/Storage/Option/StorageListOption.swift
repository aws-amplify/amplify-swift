//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct StorageListOption: StorageOption {
    public init(accessLevel: StorageAccessLevel?, prefix: String?, limit: Int?, options: Any?, targetUser: String?) {
        self.accessLevel = accessLevel
        self.options = options
        self.prefix = prefix
        self.limit = limit
        self.targetUser = targetUser
    }

    public var accessLevel: StorageAccessLevel?

    public var prefix: String?

    // Specifics the user when retrieving data for user other than self under the Protected AccessLevel
    public var targetUser: String?

    public var limit: Int?

    public var options: Any?
}
