//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct StoragePutOption: StorageOption {
    public init(accessLevel: StorageAccessLevel?,
                contentType: String?,
                metadata: [String: String]?,
                options: Any?) {
        self.accessLevel = accessLevel
        self.contentType = contentType
        self.metadata = metadata
        self.options = options
    }

    public var accessLevel: StorageAccessLevel?

    public var metadata: [String: String]?

    public var contentType: String?

    public var options: Any?
}
