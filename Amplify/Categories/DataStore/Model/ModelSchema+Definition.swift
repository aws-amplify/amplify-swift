//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

// TODO: Add the rest of the AppSync scalar types
// https://docs.aws.amazon.com/appsync/latest/devguide/scalars.html
public enum ModelFieldType: CustomStringConvertible {

    case string
    case int
    case double
    case date
    case dateTime
    case time
    case bool
    case `enum`(Any.Type)
    case model(type: Model.Type)
    case collection(of: Model.Type)

    public var description: String {
        switch self {
        case .string: return "String"
        case .int: return "Int"
        case .double: return "Float"
        case .date:  return "AWSDate"
        case .dateTime: return "AWSDateTime"
        case .time: return "AWSTime"
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
        case "Float": return .double
        case "Boolean": return .bool
        case "AWSDate": return .date
        case "AWSDateTime": return .dateTime
        case "AWSTime": return .time
        default:
            guard let model = ModelRegistry.modelType(from: type) else {
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

public struct ModelSchemaDefinition {

    internal let name: String
    public var pluralName: String?
    internal var fields: ModelFields
    internal var attributes: [ModelAttribute]

    init(name: String, pluralName: String? = nil, attributes: [ModelAttribute] = []) {
        self.name = name
        self.pluralName = pluralName
        self.fields = [:] as ModelFields
        self.attributes = attributes
    }

    public mutating func fields(_ fields: ModelFieldDefinition...) {
        fields.forEach { definition in
            let field = definition.modelField
            self.fields[field.name] = field
        }
    }

    public mutating func attributes(_ attributes: ModelAttribute...) {
        self.attributes = attributes
    }

    internal func build() -> ModelSchema {
        return ModelSchema(name: name, pluralName: pluralName, attributes: attributes, fields: fields)
    }
}

public enum ModelFieldDefinition {

    case field(name: String,
               type: ModelFieldType,
               nullability: ModelFieldNullability,
               association: ModelAssociation?,
               attributes: [ModelFieldAttribute])

    public static func field(_ key: CodingKey,
                             is nullability: ModelFieldNullability = .required,
                             ofType type: ModelFieldType = .string,
                             attributes: [ModelFieldAttribute] = [],
                             association: ModelAssociation? = nil) -> ModelFieldDefinition {
        return .field(name: key.stringValue,
                      type: type,
                      nullability: nullability,
                      association: association,
                      attributes: attributes)
    }

    public static func id(_ key: CodingKey) -> ModelFieldDefinition {
        return id(key.stringValue)
    }

    public static func id(_ name: String = "id") -> ModelFieldDefinition {
        return .field(name: name,
                      type: .string,
                      nullability: .required,
                      association: nil,
                      attributes: [.primaryKey])
    }

    public static func hasMany(_ key: CodingKey,
                               is nullability: ModelFieldNullability = .required,
                               ofType type: Model.Type,
                               associatedWith associatedKey: CodingKey) -> ModelFieldDefinition {
        return .field(key,
                      is: nullability,
                      ofType: .collection(of: type),
                      association: .hasMany(associatedWith: associatedKey))
    }

    public static func hasOne(_ key: CodingKey,
                              is nullability: ModelFieldNullability = .required,
                              ofType type: Model.Type,
                              associatedWith associatedKey: CodingKey) -> ModelFieldDefinition {
        return .field(key,
                      is: nullability,
                      ofType: .model(type: type),
                      association: .hasOne(associatedWith: associatedKey))
    }

    public static func belongsTo(_ key: CodingKey,
                                 is nullability: ModelFieldNullability = .required,
                                 ofType type: Model.Type,
                                 associatedWith associatedKey: CodingKey? = nil,
                                 targetName: String? = nil) -> ModelFieldDefinition {
        return .field(key,
                      is: nullability,
                      ofType: .model(type: type),
                      association: .belongsTo(associatedWith: associatedKey, targetName: targetName))
    }

    public var modelField: ModelField {
        guard case let .field(name,
                              type,
                              nullability,
                              association,
                              attributes) = self else {
            preconditionFailure("Unexpected enum value found: \(String(describing: self))")
        }
        return ModelField(name: name,
                          type: type.description,
                          isRequired: nullability.isRequired,
                          isArray: type.isArray,
                          attributes: attributes,
                          association: association)
    }
}
