//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public protocol ModelMetadata {
    typealias ModelProperties = [ModelProperty]

    static var properties: ModelProperties { get }

    static var name: String { get }

    static func property(forKey key: CodingKey) -> ModelProperty?

    static func isSearchable() -> Bool

    static func isIndexable() -> Bool

    static func isVersioned() -> Bool
}

extension Model where Self: ModelMetadata {
    public static var name: String {
        return String(describing: self)
    }

    public static func property(forKey key: CodingKey) -> ModelProperty? {
        return properties.first { property in
            property.metadata.key.stringValue == key.stringValue
        }
    }

    public static func isSearchable() -> Bool {
        return self is Searchable.Type
    }

    public static func isIndexable() -> Bool {
        return self is Indexable.Type
    }

    public static func isVersioned() -> Bool {
        return self is Versionable.Type
    }
}

public typealias PersistentModel = Model & ModelMetadata
