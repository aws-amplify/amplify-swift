//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
public class StorageGetResult {
    public init() {
    }
    public init(data: Data? = nil) {
        self.data = data
    }

    public init(remote: URL) {
        self.remote = remote
    }

    public var data: Data?
    public var remote: URL?
}
