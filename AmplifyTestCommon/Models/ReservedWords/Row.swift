//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public struct Row: Model {
    public let id: String
    public var group: Group

    public init(id: String = UUID().uuidString,
                group: Group) {
        self.id = id
        self.group = group
    }
}
