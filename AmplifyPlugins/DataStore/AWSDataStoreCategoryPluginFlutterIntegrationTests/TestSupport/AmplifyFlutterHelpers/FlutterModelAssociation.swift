//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public struct FlutterModelAssociation {
    
    private let associationType : String
    private let targetName : String?
    private let associatedName: String?

    init(serializedData: [String: Any]) throws {
        
        guard let associationType = serializedData["associationType"] as? String
        else {
            throw ModelSchemaError.parse(
                className: "FlutterModelAssociation",
                fieldName: "associationType",
                desiredType: "String")
        }
        self.associationType = associationType
        
        self.targetName = serializedData["targetName"] as? String
        self.associatedName = serializedData["associatedName"] as? String
    }
    
    public func convertToNativeModelAssociation() -> ModelAssociation{
        
        switch associationType {
            case "HasMany":
                return ModelAssociation.hasMany(associatedFieldName: associatedName)
            case "HasOne":
                return ModelAssociation.hasOne(associatedFieldName: associatedName)
            case "BelongsTo":
                return ModelAssociation.belongsTo(associatedFieldName: associatedName, targetName: targetName)
            default:
                preconditionFailure("Could not create a ModelAssociation from \(associationType)")
        }
    }
}

