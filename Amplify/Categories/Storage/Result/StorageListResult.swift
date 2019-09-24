//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct StorageListResult {
    public init(keys: [String]) {
        self.keys = keys
    }

    public var keys: [String]

    // TODO:
    // JS also returns
    /*
     eTag: item.ETag,
     lastModified: item.LastModified,
     size: item.Size
     */
}
