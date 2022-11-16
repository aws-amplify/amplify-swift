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
    let appSyncAssociatedIdentifiers: [String]
    let appSyncAssociatedField: String
    let apiName: String?
}

/// Metadata that contains partial information of a model
public struct AppSyncModelIdentifierMetadata: Codable {
    let identifiers: [LazyModelIdentifier]
    let apiName: String?
    
    func getIdentifiers() -> [(name: String, value: String)] {
        identifiers.map { identifier in
            return (name: identifier.name, value: identifier.value)
        }
    }
}

public struct AppSyncModelMetadataUtils {
    
    // This validation represents the requirements for adding metadata. For example,
    // It needs to have the `id` of the model so it can be injected into lazy lists as the "associatedId"
    // It needs to have the Model type from `__typename` so it can populate it as "associatedField"
    //
    // This check is currently broken for some of the CPK use cases since the identifier may not be named `id` anymore
    // and can be a composite key made up of multiple fields. Some CPK use cases like having `id` and another key
    // still works since part of the composite key is still named `id`.
    static func shouldAddMetadata(toModel graphQLData: JSONValue) -> Bool {

        guard case let .object(modelJSON) = graphQLData,
              case let .string(modelName) = modelJSON["__typename"],
              let schema = ModelRegistry.modelSchema(from: modelName) else {
              //case .string = modelJSON["id"] else {
            return false
        }

//        let primarykeys = schema.primaryKey
//        for identifierField in primarykeys.fields {
//            // Don't add metadata if any of the primary keys is missing.
//            if modelJSON[identifierField.name] == nil {
//                return false
//            }
//        }

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
        // guard case let .string(id) = modelJSON["id"] else {
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
        
        // Iterate over the associations of the model and for each association, either create the identifier metadata
        // for lazy loading belongs-to or create the model association metadata for lazy loading has-many.
        // The metadata gets decoded to the LazyModel and List implementations respectively.
        for modelField in modelSchema.fields.values {
            
            print("Iterating over \(modelField.name) isArray \(modelField.isArray) hasAssociation \(modelField.hasAssociation)")
            
            // Handle Belongs-to associations. For the current `modelField` that is a belongs-to association,
            // retrieve the data and attempt to decode to the association's modelType. If it can be decoded,
            // this means it is eager loaded and does not need to be lazy loaded. If it cannot, extract the
            // identifiers out of the data in the AppSyncModelIdentifierMetadata and store that in place for
            // the LazyModel to decode from.
            if !modelField.isArray && modelField.hasAssociation,
               let nestedModelJSON = modelJSON[modelField.name],
               case .object(let modelObject) = nestedModelJSON,
               let associatedModelName = modelField.associatedModelName,
               let associatedModelType = ModelRegistry.modelType(from: associatedModelName),
               let serializedModelObject = try? encoder.encode(modelObject) {
                
                if let modelIdentifierMetadata = createModelIdentifierMetadata(associatedModelType,
                                                                               modelObject: modelObject,
                                                                               apiName: apiName) {
                    if let serializedMetadata = try? encoder.encode(modelIdentifierMetadata),
                       let metadataJSON = try? decoder.decode(JSONValue.self, from: serializedMetadata) {
                        Amplify.API.log.verbose("Adding [\(modelField.name): \(metadataJSON)]")
                        modelJSON.updateValue(metadataJSON, forKey: modelField.name)
                    } else {
                        Amplify.API.log.error("""
                        Found assocation but failed to add metadata to existing model: \(modelJSON)
                        """)
                    }
                } else {
                    // the object is eager loaded, recursively add metadata to the eager loaded object.
                    print("object \(nestedModelJSON) is eager loaded")
                    // TODO only recusively add metadata if the codegen allows lazy loading objets.
                    if associatedModelType.rootPath != nil {
                        print("lazy model enabled - recursive addMetadata to eager loaded model \(nestedModelJSON)")
                        let nestedModelWithMetadata = addMetadata(toModel: nestedModelJSON, apiName: apiName)
                        modelJSON.updateValue(nestedModelWithMetadata, forKey: modelField.name)
                    }
                    
                }
            }
            
            // Has-Many eager loaded, with lazy loading
            if modelField.isArray && modelField.hasAssociation,
               let associatedField = modelField.associatedField,
               var nestedModelJSON = modelJSON[modelField.name],
               case .object(var graphQLDataObject) = nestedModelJSON,
               case .array(var graphQLDataArray) = graphQLDataObject["items"] {
                
                for (index, item) in graphQLDataArray.enumerated() {
                    let modelJSON = AppSyncModelMetadataUtils.addMetadata(toModel: item,
                                                                          apiName: apiName)
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
                    log.error("""
                        Found eager loaded assocation but failed to add payload to: \(modelJSON)
                        """)
                }
                
            }
            
            // Handle Has-many. Store the association data (parent's identifier and field name) only when the model
            // at the association is empty. If it's not empty, that means the has-many has been eager loaded.
            // For example, when traversing the Post's fields and encounters the has-many association Comment, store
            // the association metadata containing the post's identifier at comment, to be decoded to the List
            // This allows the list to perform lazy loading of the Comments with a filter on the post's identifier.
            if modelField.isArray && modelField.hasAssociation,
               let associatedField = modelField.associatedField,
               modelJSON[modelField.name] == nil {
                let appSyncModelMetadata = AppSyncModelMetadata(appSyncAssociatedIdentifiers: identifiers,
                                                                appSyncAssociatedField: associatedField.name,
                                                                apiName: apiName)
                if let serializedMetadata = try? encoder.encode(appSyncModelMetadata),
                   let metadataJSON = try? decoder.decode(JSONValue.self, from: serializedMetadata) {
                    log.verbose("Adding [\(modelField.name): \(metadataJSON)]")
                    modelJSON.updateValue(metadataJSON, forKey: modelField.name)
                } else {
                    log.error("""
                        Found assocation but failed to add metadata to existing model: \(modelJSON)
                        """)
                }
            }
        }

        return JSONValue.object(modelJSON)
    }
    
    // At this point, we know the model cannot be decoded to the fully model
    // so extract the primary key and values out.
    static func createModelIdentifierMetadata(_ associatedModel: Model.Type,
                                              modelObject: [String: JSONValue],
                                              apiName: String?) -> AppSyncModelIdentifierMetadata? {
        let primarykeys = associatedModel.schema.primaryKey
        var identifiers = [LazyModelIdentifier]()
        for identifierField in primarykeys.fields {
            if case .string(let identifierValue) = modelObject[identifierField.name] {
                identifiers.append(.init(name: identifierField.name, value: identifierValue))
            }
        }
        
        // How do we determine if the model is eager loaded or not?
        // eager loaded means, all fields are available
        // lazy loaded means only identifiers are available.
        
        // what if the count of eager loaded == lazy loaded ? then it should always be
        
        // if the number of fields extracted + typename != the data object's fields, then this is not for eager loading.
        if (identifiers.count + 1) != (modelObject.keys.count) {
            print("returning nil for \(associatedModel.modelName)")
            return nil
        }
        
        if !identifiers.isEmpty {
            print("Creating not loaded \(associatedModel.modelName) object of \(modelObject)")
            return AppSyncModelIdentifierMetadata(identifiers: identifiers, apiName: apiName)
        } else {
            print("Creating not loaded \(associatedModel.modelName)")
            return nil
        }
    }
    
    // Retrieve Identifiers (for creating AppSyncModelMetadata)
    static func retrieveIdentifiers(_ modelJSON: [String: JSONValue], _ schema: ModelSchema) -> [String]? {
        let primarykeys = schema.primaryKey
        var identifiers = [String]()
        for identifierField in primarykeys.fields {
            // retrieve the targetName here instead of the name of the field on the model.
            // we don't have the target name on here because it's the
            if case .string(let id) = modelJSON[identifierField.name] {
                print("Found key value \(identifierField.name) value: \(id)")
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

extension AppSyncModelMetadataUtils: DefaultLogger { }
