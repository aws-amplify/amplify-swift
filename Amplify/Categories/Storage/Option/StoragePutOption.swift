//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
public class StoragePutOption: StorageOption {
    public var accessLevel: AccessLevel?

    public var options: Any?

    public var contentType: String?
    public var metadata: [String: String]?
}
