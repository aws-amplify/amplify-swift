//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public enum ModelAttribute {
    case index
}

public enum ModelFieldAttribute {
    case primaryKey
    case connected(name: String)
}

public struct ModelField {
    public let name: String
    public let type: String
    public let isRequired: Bool
    public let isArray: Bool
    public let attributes: [ModelFieldAttribute]

    public var isPrimaryKey: Bool {
        // TODO change it to check for the .primaryKey attribute instead
        return name == "id"
    }

    public var isConnected: Bool {
        return !attributes.filter {
            guard case .connected = $0 else {
                return false
            }
            return true
        }.isEmpty
    }

    init(name: String,
         type: String,
         isRequired: Bool = false,
         isArray: Bool = false,
         attributes: [ModelFieldAttribute] = []) {
        self.name = name
        self.type = type
        self.isRequired = isRequired
        self.isArray = isArray
        self.attributes = attributes
    }
}

public typealias ModelFields = [String: ModelField]

public struct ModelSchema {

    public let name: String
    public let fields: ModelFields

    public let allFields: [ModelField]

    public var primaryKey: ModelField {
        guard let primaryKey = fields.first(where: { $1.isPrimaryKey }) else {
            preconditionFailure("Primary Key not defined for `\(name)`")
        }
        return primaryKey.value
    }

    init(name: String, fields: ModelFields = [:]) {
        self.name = name
        self.fields = fields

        // keep a sorted copy of all the fields as an array
        self.allFields = fields.sortedFields()
    }

    public func field(withName name: String) -> ModelField? {
        return fields[name]
    }

}

extension Dictionary where Key == String, Value == ModelField {

    /// Returns an array of the values sorted by some pre-defined rules:
    ///
    /// 1. primary key comes always first
    /// 2. foreign keys come always at the end
    /// 3. the other fields are sorted alphabetically
    ///
    /// This is useful so code that uses the fields to generate queries and other
    /// persistence-related operations guarantee that the results are always consistent.
    func sortedFields() -> [Value] {
        return values.sorted { one, other in
            if one.isPrimaryKey {
                return true
            }
            if other.isPrimaryKey {
                return false
            }
            if one.isConnected && !other.isConnected {
                return false
            }
            if !one.isConnected && other.isConnected {
                return true
            }
            return one.name < other.name
        }
    }
}
