//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

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
        case .enum(let type): return String(describing: type)
        case .model(let type): return String(describing: type)
        case .collection(let ofType): return String(describing: ofType)
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
            guard let model = modelType(from: type) else {
                preconditionFailure("Model with name \(type) could not be found.")
            }
            return isArray ? .collection(of: model) : .model(type: model)
        }
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

    init(name: String) {
        self.name = name
        self.fields = [:] as ModelFields
        self.attributes = []
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
        return ModelSchema(name: name, fields: fields)
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
