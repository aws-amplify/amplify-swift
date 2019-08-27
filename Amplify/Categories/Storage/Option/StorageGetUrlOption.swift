//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
public class StorageGetUrlOption: StorageOption {
    public init(accessLevel: AccessLevel?, expires: Int?, options: Any?) {
        self.accessLevel = accessLevel
        self.expires = expires
        self.options = options
    }

    public var accessLevel: AccessLevel?

    public var expires: Int?

    public var options: Any?
}
