//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Model where Self: Indexable {
    public static func index(name: String? = nil,
                             sortBy sortKey: CodingKey? = nil,
                             forKeys keys: CodingKey...) -> Index {
        return Index(keys: keys, name: name, sortBy: sortKey)
    }
}
