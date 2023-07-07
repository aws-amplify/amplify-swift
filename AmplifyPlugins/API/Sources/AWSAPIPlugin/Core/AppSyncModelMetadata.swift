//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

/// Holds the methods to traverse and maniupulate the response data object by injecting
public struct AppSyncModelMetadataUtils {
    
    // A fairly light check to make sure the payload is an object and we have the schema for `addMetadata`.
    // Note: `addMetadata` should be very tightly checking the associated fields to determine when it should add
    // metadata. Do we still need to do this anymore?
    static func shouldAddMetadata(toModel graphQLData: JSONValue) -> Bool {
        guard case let .object(modelJSON) = graphQLData,
              case let .string(modelName) = modelJSON["__typename"],
              ModelRegistry.modelSchema(from: modelName) != nil else {
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

        guard let identifiers = retrieveIdentifiers(modelJSON, modelSchema) else {
            Amplify.API.log.debug("""
                Could not retrieve the identifiers from the return value. Be sure to include the model's `id` in \
                the selection set of the GraphQL operation. GraphQL:
                \(graphQLData)
                """)
            return graphQLData
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
        
        // Iterate over the associations of the model and for each association, either create the identifier metadata
        // for lazy loading belongs-to or create the model association metadata for lazy loading has-many.
        // The metadata gets decoded to the LazyReference and List implementations respectively.
        for modelField in modelSchema.fields.values {
            
            // Scenario: Belongs-to associations. For the current `modelField` that is a belongs-to association,
            // retrieve the data and attempt to decode to the association's modelType. If it can be decoded,
            // this means it is eager loaded and does not need to be lazy loaded. If it cannot, extract the
            // identifiers out of the data in the AppSyncModelIdentifierMetadata and store that in place for
            // the LazyModel to decode from.
            if !modelField.isArray && modelField.hasAssociation,
               let nestedModelJSON = modelJSON[modelField.name],
               case .object(let modelObject) = nestedModelJSON,
               let associatedModelName = modelField.associatedModelName,
               let associatedModelType = ModelRegistry.modelType(from: associatedModelName) {
                
                // Scenario: Belongs-To Primary Keys only are available for lazy loading
                if let modelIdentifierMetadata = createModelIdentifierMetadata(associatedModelType,
                                                                               modelObject: modelObject,
                                                                               apiName: apiName) {
                    if let serializedMetadata = try? encoder.encode(modelIdentifierMetadata),
                       let metadataJSON = try? decoder.decode(JSONValue.self, from: serializedMetadata) {
                        Amplify.API.log.verbose("Adding [\(modelField.name): \(metadataJSON)]")
                        modelJSON.updateValue(metadataJSON, forKey: modelField.name)
                    } else {
                        Amplify.API.log.error("""
                        Found association but failed to add metadata to existing model: \(modelJSON)
                        """)
                    }
                }
                // Scenario: Belongs-To object is eager loaded
                // add metadata to its fields, to create not loaded LazyReference objects
                // only if the model type allowsfor lazy loading functionality
                else if associatedModelType.rootPath != nil {
                    let nestedModelWithMetadata = addMetadata(toModel: nestedModelJSON, apiName: apiName)
                    modelJSON.updateValue(nestedModelWithMetadata, forKey: modelField.name)
                }
                // otherwise do nothing to the data.
            }
            
            // Scenario: Has-Many eager loaded or empty payloads.
            if modelField.isArray && modelField.hasAssociation,
               let associatedModelName = modelField.associatedModelName {
                
                // Scenario: Has-many items array is missing.
                // Store the association data (parent's identifier and field name)
                // This allows the list to perform lazy loading of child items using parent identifier as the predicate
                if modelJSON[modelField.name] == nil {
                    let appSyncModelMetadata = AppSyncListDecoder.Metadata(appSyncAssociatedIdentifiers: identifiers,
                                                                           appSyncAssociatedFields: modelField.associatedFieldNames,
                                                                           apiName: apiName)
                    if let serializedMetadata = try? encoder.encode(appSyncModelMetadata),
                       let metadataJSON = try? decoder.decode(JSONValue.self, from: serializedMetadata) {
                        log.verbose("Adding [\(modelField.name): \(metadataJSON)]")
                        modelJSON.updateValue(metadataJSON, forKey: modelField.name)
                    } else {
                        log.error("""
                         Found association but failed to add metadata to existing model: \(modelJSON)
                         """)
                    }
                }
                
                // Scenario: Has-Many items array is eager loaded as `nestedModelJSON`
                // If the model types allow for lazy loading, inject the metadata at each item of `nestedModelJSON`
                else if let nestedModelJSON = modelJSON[modelField.name],
                   case .object(var graphQLDataObject) = nestedModelJSON,
                   case .array(var graphQLDataArray) = graphQLDataObject["items"],
                   let associatedModelType = ModelRegistry.modelType(from: associatedModelName),
                   associatedModelType.rootPath != nil {
                    
                    for (index, item) in graphQLDataArray.enumerated() {
                        let modelJSON = AppSyncModelMetadataUtils.addMetadata(toModel: item, apiName: apiName)
                        graphQLDataArray[index] = modelJSON
                    }
                    
                    graphQLDataObject["items"] = JSONValue.array(graphQLDataArray)
                    let payload = AppSyncListPayload(graphQLData: JSONValue.object(graphQLDataObject),
                                                     apiName: apiName,
                                                     variables: nil)
                    
                    if let serializedPayload = try? encoder.encode(payload),
                       let payloadJSON = try? decoder.decode(JSONValue.self, from: serializedPayload) {
                        log.verbose("Adding [\(modelField.name): \(payloadJSON)]")
                        modelJSON.updateValue(payloadJSON, forKey: modelField.name)
                    } else {
                        log.error("Found eager loaded list, failed to add payload to: \(modelJSON)")
                    }
                }
            }
        }

        return JSONValue.object(modelJSON)
    }
    
    /// Extract the identifiers from the `modelObject`. The number of identifiers extracted compared to the number of
    /// fields on the `modelObject` is useful determining if the `modelOject` is eager or lazy loaded. If the identifiers
    /// plus one additional field (`__typename`) doesn't match the number of keys on the `modelObject` then there
    /// are more keys in the `modelObject` which means it was eager loaded.
    static func createModelIdentifierMetadata(_ associatedModel: Model.Type,
                                              modelObject: [String: JSONValue],
                                              apiName: String?) -> AppSyncModelDecoder.Metadata? {
        let primarykeys = associatedModel.schema.primaryKey
        var identifiers = [LazyReferenceIdentifier]()
        for identifierField in primarykeys.fields {
            if case .string(let identifierValue) = modelObject[identifierField.name] {
                identifiers.append(.init(name: identifierField.name, value: identifierValue))
            }
        }
        var modelObject = modelObject
        modelObject["__typename"] = nil
        modelObject["_lastChangedAt"] = nil
        modelObject["_deleted"] = nil
        modelObject["_version"] = nil
        if !identifiers.isEmpty && (identifiers.count) == modelObject.keys.count {
            return AppSyncModelDecoder.Metadata(identifiers: identifiers, apiName: apiName)
        } else {
            return nil
        }
    }
    
    /// Retrieve just the identifiers from the current model. These identifiers are later used
    /// for creating `AppSyncListDecoder.Metadata` payloads for decoding.
    static func retrieveIdentifiers(_ modelJSON: [String: JSONValue], _ schema: ModelSchema) -> [String]? {
        let primarykeys = schema.primaryKey
        var identifiers = [String]()
        for identifierField in primarykeys.fields {
            if case .string(let id) = modelJSON[identifierField.name] {
                identifiers.append(id)
            }
        }
        if !identifiers.isEmpty {
            return identifiers
        } else {
            return nil
        }
    }
}

extension AppSyncModelMetadataUtils: DefaultLogger {
    public static var log: Logger {
        Amplify.Logging.logger(forCategory: CategoryType.api.displayName)
    }
    public var log: Logger {
        Self.log
    }
}
