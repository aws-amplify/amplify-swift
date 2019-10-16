//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/*
 All persistent models should confirm to the Model protocol.
 */
public protocol Model: Codable {
    static var primaryKey: ModelKey { get }
}

public typealias ModelKey = CodingKey & ModelProperty

extension Model where Self: Codable {
    public subscript(_ key: String) -> Any? {
        let mirror = Mirror(reflecting: self)
        let property = mirror.children.first { $0.label == key }
        return property == nil ? nil : property!.value
    }

    public subscript(_ key: CodingKey) -> Any? {
        return self[key.stringValue]
    }
}
