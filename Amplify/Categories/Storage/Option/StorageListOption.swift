//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public class StorageListOption: StorageOption {
    public init(accessLevel: AccessLevel?, prefix: String?, limit: Int?, options: Any?) {
        self.accessLevel = accessLevel
        self.options = options
        self.prefix = prefix
        self.limit = limit
    }

    public var accessLevel: AccessLevel?

    public var prefix: String?

    public var limit: Int?

    public var options: Any?
}
