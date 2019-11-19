//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Defines a storage schema. This immutable struct holds a reference to all the available
/// `Model` types and their respective `ModelSchema`.
public struct Schema {

    /// The `ModelSchema` instances indexed by their names (i.e. the type name)
    let models: [String: ModelSchema]

    /// The current version of the schema
    let version: Int

}

public enum ModelAttribute {
    /// TODO: What does this mean?
    case index

    /// Instances of this model are syncable to the cloud via the API category
    case isSyncable

    /// This model is used by the Amplify system or a plugin, and should not be used by the app developer
    case isSystem
}

public enum ModelFieldAttribute {
    case primaryKey
    case connected(name: String)
}

public struct ModelField {

    public let name: String
    public let targetName: String?
    public let type: String
    public let isRequired: Bool
    public let isArray: Bool
    public let attributes: [ModelFieldAttribute]

    public var isPrimaryKey: Bool {
        return name == "id"
    }

    public var isConnected: Bool {
        return attributes.contains {
            guard case .connected = $0 else {
                return false
            }
            return true
        }
    }

    init(name: String,
         targetName: String? = nil,
         type: String,
         isRequired: Bool = false,
         isArray: Bool = false,
         attributes: [ModelFieldAttribute] = []) {
        self.name = name
        self.targetName = targetName
        self.type = type
        self.isRequired = isRequired
        self.isArray = isArray
        self.attributes = attributes
    }
}

public typealias ModelFields = [String: ModelField]

public struct ModelSchema {

    public let name: String
    public let targetName: String?
    public let fields: ModelFields
    public let attributes: [ModelAttribute]
    public let sortedFields: [ModelField]
    public var primaryKey: ModelField {
        guard let primaryKey = fields.first(where: { $1.isPrimaryKey }) else {
            preconditionFailure("Primary Key not defined for `\(name)`")
        }
        return primaryKey.value
    }

    init(name: String,
         targetName: String? = nil,
         attributes: [ModelAttribute] = [],
         fields: ModelFields = [:]) {
        self.name = name
        self.targetName = targetName
        self.attributes = attributes
        self.fields = fields

        self.sortedFields = fields.sortedFields()
    }

    public func field(withName name: String) -> ModelField? {
        return fields[name]
    }

}

public extension ModelSchema {
    var isSyncable: Bool {
        attributes.contains(.isSyncable)
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
