//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public class StorageGetOption: StorageOption {
    public init(accessLevel: AccessLevel?, options: Any?) {
        self.accessLevel = accessLevel
        self.options = options
    }

    public var accessLevel: AccessLevel?

    public var options: Any?
}
