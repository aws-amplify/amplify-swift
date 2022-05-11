//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

struct TypeKey: Hashable {
    let type: Any.Type

    init(type: Any.Type) {
        self.type = type
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(type))
    }

    static func ==(lhs: TypeKey, rhs: TypeKey) -> Bool {
        lhs.type == rhs.type
    }
}
