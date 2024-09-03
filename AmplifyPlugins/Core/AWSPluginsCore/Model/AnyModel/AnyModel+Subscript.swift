//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Implement dynamic access to properties of a `Model`.
///
/// ```swift
/// let id = model["id"]
/// ```
public extension AnyModel {

    subscript(_ key: String) -> Any? {
        let mirror = Mirror(reflecting: instance)
        let property = mirror.children.first { $0.label == key }
        return property?.value
    }

    subscript(_ key: CodingKey) -> Any? {
        return self[key.stringValue]
    }

}
