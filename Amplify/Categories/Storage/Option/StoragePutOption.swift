//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct StoragePutOption {

    public var accessLevel: StorageAccessLevel?

    public var metadata: [String: String]?

    public var contentType: String?

    public var options: Any?

    // TODO: tags (may be in options)
    // TODO: expires (may be in metadata)
    public init(accessLevel: StorageAccessLevel?,
                contentType: String? = nil,
                metadata: [String: String]? = nil,
                options: Any? = nil) {
        self.accessLevel = accessLevel
        self.contentType = contentType
        self.metadata = metadata
        self.options = options
    }
}
