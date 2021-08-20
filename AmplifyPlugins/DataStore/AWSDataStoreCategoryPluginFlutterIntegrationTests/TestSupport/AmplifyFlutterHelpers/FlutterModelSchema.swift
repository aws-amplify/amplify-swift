//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

struct FlutterModelSchema {
    
    let name: String
    let fields: [String: FlutterModelField]
    let pluralName: String?
    let authRules: [FlutterAuthRule]?
    
    // Not used for now
    let attributes: [ModelAttribute] = []
    
    init(serializedData: [String: Any]) throws {
        
        guard let name = serializedData["name"] as? String else {
            throw ModelSchemaError.parse(
                className: "FlutterModelSchema",
                fieldName: "name",
                desiredType: "String")
        }
        self.name = name
        
        guard let inputFieldsMap = serializedData["fields"] as? [String: [String: Any]] else {
            throw ModelSchemaError.parse(
                className: "FlutterModelSchema",
                fieldName: "fields",
                desiredType: "[String: [String: Any]]")
        }
        self.fields = try inputFieldsMap.mapValues {
            try FlutterModelField.init(serializedData: $0)
        }

        self.pluralName = serializedData["pluralName"] as? String
        
        if let inputAuthRulesMap = serializedData["authRules"] as? [[String:Any]]{
            self.authRules = try inputAuthRulesMap.map {
                try FlutterAuthRule(serializedData: $0)
            }
        }
        else {
            self.authRules = nil
        }


    }
    
    public func convertToNativeModelSchema() throws -> ModelSchema {
        return ModelSchema.init(
            name: name,
            pluralName: pluralName,
            authRules: authRules?.map{
                            $0.convertToNativeAuthRule()
                        } ?? [AuthRule](),
            attributes: attributes,
            fields: try fields.mapValues { try $0.convertToNativeModelField() }
        )
    }
}
