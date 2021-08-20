//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import Foundation
import Amplify

public struct FlutterModelFieldType {
    public let fieldType : String
    public let ofModelName : String?
    
    
    init(serializedData: [String: Any]) throws {
        
        guard let fieldType = serializedData["fieldType"] as? String
        else {
            throw ModelSchemaError.parse(
                className: "FlutterModelFieldType",
                fieldName: "fieldType",
                desiredType: "String")
        }
        self.fieldType = fieldType
        
        self.ofModelName = serializedData["ofModelName"] as? String
        
    }
    
    public func convertToNativeModelField() throws -> ModelFieldType {
        
        switch fieldType {
            case "string":
                return ModelFieldType.string
            case "int":
                return ModelFieldType.int
            case "double":
                return ModelFieldType.double
            case "date":
                return ModelFieldType.date
            case "dateTime":
                return ModelFieldType.dateTime
            case "time":
                return ModelFieldType.time
            case "timestamp":
                return ModelFieldType.timestamp
            case "bool":
                return ModelFieldType.bool
            case "enumeration":
                return ModelFieldType.string
            case "model":
                guard let ofModelName = ofModelName
                else {
                    throw ModelSchemaError.parse(
                        className: "FlutterModelFieldType",
                        fieldName: "ofModelName",
                        desiredType: "String")
                }
                return ModelFieldType.model(name: ofModelName)
            case "collection" :
                guard let ofModelName = ofModelName
                else {
                    throw ModelSchemaError.parse(
                        className: "FlutterModelFieldType",
                        fieldName: "ofModelName",
                        desiredType: "String")
                }
                do {
                    let embeddedType = try getPrimitiveTypeForEmbeddedCollection(typeName: ofModelName)
                    return ModelFieldType.embeddedCollection(of: embeddedType, schema: nil)
                } catch {
                    return ModelFieldType.collection(of: ofModelName)
                }
            default:
                preconditionFailure("Could not create a ModelFieldType from \(fieldType)")
        }
    }

    func getPrimitiveTypeForEmbeddedCollection(typeName: String) throws -> Codable.Type {
        switch typeName {
        case "int":
            return Int.self
        case "string":
            return String.self
        case "double":
            return Double.self
        case "bool":
            return Bool.self
        case "dateTime":
            return Temporal.DateTime.self
        case "time":
            return Temporal.Time.self
        case "date":
            return Temporal.Date.self
        case "timestamp":
            return Int64.self
        case "enumeration":
            return String.self
        default:
            throw "\(typeName) is not a known primitive type"
        }
    }
}
