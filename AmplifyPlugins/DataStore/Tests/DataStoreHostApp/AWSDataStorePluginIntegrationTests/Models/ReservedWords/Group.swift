//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public struct Group: Model {
    public let id: String

    public init(id: String = UUID().uuidString) {
        self.id = id
    }
}
