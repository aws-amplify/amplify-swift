//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct StorageGetOption: StorageOption {
    public init(local: URL?, download: Bool?, accessLevel: AccessLevel?, expires: Int?, options: Any?,
                targetUser: String?) {
        self.local = local
        self.download = download
        self.accessLevel = accessLevel
        self.expires = expires
        self.options = options
        self.targetUser = targetUser
    }

    // The path to a local file.
    public var local: URL?

    // The flag to determine whether to return remoteURL or download to memory or local URL
    public var download: Bool?

    // Specifics the user when retrieving data for user other than self under the Protected AccessLevel
    public var targetUser: String?

    public var accessLevel: AccessLevel?

    public var expires: Int?

    public var options: Any?
}
