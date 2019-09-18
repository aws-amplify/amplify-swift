//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct StorageRemoveOptions {
    public var accessLevel: StorageAccessLevel?

    public var options: Any?

    public init(accessLevel: StorageAccessLevel?, options: Any?) {
        self.accessLevel = accessLevel
        self.options = options
    }
}
