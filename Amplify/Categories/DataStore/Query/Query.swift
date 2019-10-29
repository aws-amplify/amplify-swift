//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct Query<Value> {

    public let string: String
    public let arguments: [Value]

    public init(_ string: String,
                arguments: [Value] = []) {
        self.string = string
        self.arguments = arguments
    }
}
