//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Defines the relationship type between two models. The type of relationship is
/// important when defining how to store and query them. Each relationship have
/// its own rules depending on the storage mechanism. For example, on SQL a
/// `manyToOne`/`oneToMany` relationship has a "foreign key" stored on the "many"
/// side of the relation.
public enum ModelRelationship {
    case manyToMany(Model.Type)
    case manyToOne(Model.Type)
    case oneToMany(Model.Type)
    case oneToOne(Model.Type, name: String)
}

public enum ModelFieldType: CustomStringConvertible {

    case string
    case int
    case double
    case date
    case dateTime
    case bool
    case `enum`(type: Any.Type)
    case model(type: Model.Type)
    case collection(of: Model.Type)

    public var description: String {
        switch self {
        case .string: return "String"
        case .int: return "Int"
        case .double: return "Double"
        case .date:  return "AWSDate"
        case .dateTime: return "AWSDateTime"
        case .bool: return "Boolean"
        case .enum(let anyType): return String(describing: anyType)
        case .model(let modelType): return modelType.modelName
        case .collection(let modelType): return modelType.modelName
        }
    }

    public var isArray: Bool {
        switch self {
        case .collection:
            return true
        default:
            return false
        }
    }
}

extension ModelField {

    public var typeDefinition: ModelFieldType {
        switch type {
        case "String": return .string
        case "Int": return .int
        case "Double": return .double
        case "Boolean": return .bool
        case "AWSDate": return .date
        case "AWSDateTime": return .dateTime
        default:
            guard let model = ModelRegistry.modelType(from: type) else {
                preconditionFailure("Model with name \(type) could not be found.")
            }
            return isArray ? .collection(of: model) : .model(type: model)
        }
    }

    /// If the field represents a relationship (aka connected) returns the `Model.Type` of
    /// the connection. Connected types are represented by `.model(type)` and `.collection(type)`.
    /// - seealso: `ModelFieldType`
    public var connectedModel: Model.Type? {
        switch typeDefinition {
        case .model(let type), .collection(let type):
            return type
        default:
            return nil
        }
    }

    /// This calls `connectedModel` but enforces that the field must represent a relationship.
    /// In case the field type is not a `Model.Type` is calls `preconditionFailure`. Consumers
    /// should fix their models in order to recover from it, since connected models are required
    /// to be of `Model.Type`.
    ///
    /// **Note:** as a maintainer, make sure you use this computed property only when context
    /// allows (i.e. the field is a valid relatioship, such as foreign keys).
    public var requiredConnectedModel: Model.Type {
        guard let modelType = connectedModel else {
            preconditionFailure("""
            Model fields that are foreign keys must be connected to another Model.
            Check the `ModelSchema` section of your "\(name)+Schema.swift" file.
            """)
        }
        return modelType
    }

    public var relatioship: ModelRelationship? {
        switch typeDefinition {
        case .collection(let modelType):
            // TODO find the other side of the relationship and infer the type correctly
            // it might also be a .manyToMany
            return .oneToMany(modelType)
        case .model(let modelType):
            // TODO find the other side of the relationship and infer the type correctly
            // it might also be a .oneToOne
            return .manyToOne(modelType)
        default:
            return nil
        }
    }

    public var isRelationshipOwner: Bool {
        // TODO improve connected model ownership (i.e. foreignKey side)
        // this depends on the relationship type defined by `relationship`
        return isConnected && !isArray
    }
}

public enum ModelFieldNullability {
    case optional
    case required

    var isRequired: Bool {
        switch self {
        case .optional:
            return false
        case .required:
            return true
        }
    }
}

public enum ModelFieldRelationship {

    case manyToOne(_ modelType: Model.Type)
    case manyToMany(_ modelType: Model.Type)
    case oneToMany(_ modelType: Model.Type)
    case oneToOne(_ modelType: Model.Type)

    var fieldType: ModelFieldType {
        switch self {
        case .oneToMany(let modelType), .manyToMany(let modelType):
            return .collection(of: modelType)
        case .manyToOne(let modelType), .oneToOne(let modelType):
            return .model(type: modelType)
        }
    }
}

public struct ModelSchemaDefinition {

    internal let name: String
    internal var fields: ModelFields
    internal var attributes: [ModelAttribute]

    init(name: String, attributes: [ModelAttribute] = []) {
        self.name = name
        self.fields = [:] as ModelFields
        self.attributes = attributes
    }

    public mutating func fields(_ fields: ModelFieldDefinition...) {
        fields.forEach { definition in
            let field = definition.asModelField
            self.fields[field.name] = field
        }
    }

    public mutating func attributes(_ attributes: ModelAttribute...) {
        self.attributes = attributes
    }

    internal func build() -> ModelSchema {
        return ModelSchema(name: name, attributes: attributes, fields: fields)
    }
}

public enum ModelFieldDefinition {

    case field(name: String,
               type: ModelFieldType,
               nullability: ModelFieldNullability,
               attributes: [ModelFieldAttribute])

    public static func field(_ key: CodingKey,
                             is nullability: ModelFieldNullability = .optional,
                             ofType type: ModelFieldType = .string,
                             _ attributes: ModelFieldAttribute...) -> ModelFieldDefinition {
        return .field(name: key.stringValue,
                      type: type,
                      nullability: nullability,
                      attributes: attributes)
    }

    public static func field(name: String,
                             is nullability: ModelFieldNullability = .optional,
                             ofType type: ModelFieldType = .string,
                             _ attributes: ModelFieldAttribute...) -> ModelFieldDefinition {
        return .field(name: name,
                      type: type,
                      nullability: nullability,
                      attributes: attributes)
    }

    public static func id(_ name: CodingKey) -> ModelFieldDefinition {
        return id(name: name.stringValue)
    }

    public static func id(name: String = "id") -> ModelFieldDefinition {
        return .field(name: name,
                      type: .string,
                      nullability: .required,
                      attributes: [.primaryKey])
    }

    public static func connected(name: String,
                                 _ relationshipType: ModelFieldRelationship,
                                 is nullability: ModelFieldNullability = .optional,
                                 withName connectionName: String) -> ModelFieldDefinition {
        let type = relationshipType.fieldType
        return field(name: name,
                     is: nullability,
                     ofType: type,
                     .connected(name: connectionName))
    }

    public static func connected(_ key: CodingKey,
                                 _ relationshipType: ModelFieldRelationship,
                                 is nullability: ModelFieldNullability = .optional,
                                 withName connectionName: String) -> ModelFieldDefinition {
        return connected(name: key.stringValue,
                         relationshipType,
                         is: nullability,
                         withName: connectionName)
    }

    public var asModelField: ModelField {
        guard case let .field(name, type, nullability, attributes) = self else {
            preconditionFailure("Unexpected enum value found: \(String(describing: self))")
        }
        return ModelField(name: name,
                          type: type.description,
                          isRequired: nullability.isRequired,
                          isArray: type.isArray,
                          attributes: attributes)
    }
}
