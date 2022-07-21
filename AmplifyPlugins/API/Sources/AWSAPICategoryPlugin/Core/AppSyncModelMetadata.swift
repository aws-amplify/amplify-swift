//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Metadata that contains information about an associated parent object.
public struct AppSyncModelMetadata: Codable {
    let appSyncAssociatedId: String
    let appSyncAssociatedField: String
    let apiName: String?
}

public struct AppSyncModelMetadataUtils {
    static func shouldAddMetadata(toModel graphQLData: JSONValue) -> Bool {
        guard case let .object(modelJSON) = graphQLData,
              case let .string(modelName) = modelJSON["__typename"],
              ModelRegistry.modelSchema(from: modelName) != nil,
              case .string = modelJSON["id"] else {
            return false
        }

        return true
    }

    static func addMetadata(toModelArray graphQLDataArray: [JSONValue],
                            apiName: String?) -> [JSONValue] {
        return graphQLDataArray.map { (graphQLData) -> JSONValue in
            addMetadata(toModel: graphQLData, apiName: apiName)
        }
    }

    static func addMetadata(toModel graphQLData: JSONValue,
                            apiName: String?) -> JSONValue {
        guard case var .object(modelJSON) = graphQLData else {
            Amplify.API.log.debug("Not an model object: \(graphQLData)")
            return graphQLData
        }
        guard case let .string(modelName) = modelJSON["__typename"] else {
            Amplify.API.log.debug("""
                Could not retrieve the `__typename` attribute from the return value. Be sure to include __typename in \
                the selection set of the GraphQL operation. GraphQL:
                \(graphQLData)
                """)
            return graphQLData
        }
        guard let modelSchema = ModelRegistry.modelSchema(from: modelName) else {
            Amplify.API.log.debug("""
                Missing Model Schema for \(modelName). GraphQL Response: \(graphQLData)
                """)
            return graphQLData
        }

        guard case let .string(id) = modelJSON["id"] else {
            Amplify.API.log.debug("""
                Could not retrieve the `id` attribute from the return value. Be sure to include `id` in \
                the selection set of the GraphQL operation. GraphQL:
                \(graphQLData)
                """)
            return graphQLData
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
        // Iterate over the associations of the model and for each association, store its association data when
        // the object at the association is empty. For example, if the modelType is a Post and has a field that is an
        // array association like Comment, store the post's identifier and the ModelField name of the parent, ie.
        // "post" in the comments object as metadata.
        for modelField in modelSchema.fields.values {
            if modelField.isArray && modelField.hasAssociation,
               let associatedField = modelField.associatedField,
               modelJSON[modelField.name] == nil {
                let appSyncModelMetadata = AppSyncModelMetadata(appSyncAssociatedId: id,
                                                                appSyncAssociatedField: associatedField.name,
                                                                apiName: apiName)
                if let serializedMetadata = try? encoder.encode(appSyncModelMetadata),
                   let metadataJSON = try? decoder.decode(JSONValue.self, from: serializedMetadata) {
                    modelJSON.updateValue(metadataJSON, forKey: modelField.name)
                } else {
                    Amplify.API.log.error("""
                        Found assocation but failed to add metadata to existing model: \(modelJSON)
                        """)
                }
            }
        }

        return JSONValue.object(modelJSON)
    }
}
