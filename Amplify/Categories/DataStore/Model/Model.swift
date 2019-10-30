//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// All persistent models should conform to the Model protocol.
public protocol Model: Codable {
    static var schema: ModelSchema { get }
}

/// Alias of Model identifier (i.e. primary key)
public typealias Identifier = String

// MARK: - Model subscript

/// Implement dynamic access to properties of a `Model`.
///
/// ```swift
/// let id = model["id"]
/// ```
extension Model {

    public subscript(_ key: String) -> Any? {
        let mirror = Mirror(reflecting: self)
        let property = mirror.children.first { $0.label == key }
        return property == nil ? nil : property!.value
    }

    public subscript(_ key: CodingKey) -> Any? {
        return self[key.stringValue]
    }

}
