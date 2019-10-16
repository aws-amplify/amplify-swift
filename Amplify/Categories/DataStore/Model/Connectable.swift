//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct ModelConnection {
    let name: String
    let keyField: CodingKey?
    let sortField: CodingKey?
}

public protocol Connectable {
    static var connections: [ModelConnection] { get }

    static func connection(name: String, keyField: CodingKey?, sortField: CodingKey?) -> ModelConnection
}
