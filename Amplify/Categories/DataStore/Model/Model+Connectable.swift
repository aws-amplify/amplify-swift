//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Model where Self: Connectable {
    public static func connection(name: String,
                                  keyField: CodingKey? = nil,
                                  sortField: CodingKey? = nil) -> ModelConnection {
        return ModelConnection(name: name, keyField: keyField, sortField: sortField)
    }
}
