//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// This decoder is registered and used to detect various data payloads to store
/// inside an `AppSyncModelProvider` when decoding to the `LazyReference` as a "not yet loaded" Reference. If the data payload
/// can be decoded to the Model, then the model provider is created as a "loaded" reference.
public struct AppSyncModelDecoder: ModelProviderDecoder {
    
    /// Metadata that contains metadata of a model, specifically the identifiers used to hydrate the model.
    struct Metadata: Codable {
        let identifiers: [LazyReferenceIdentifier]
        let apiName: String?
        
        func getIdentifiers() -> [(name: String, value: String)] {
            identifiers.map { identifier in
                return (name: identifier.name, value: identifier.value)
            }
        }
    }
    
    public static func shouldDecode<ModelType: Model>(modelType: ModelType.Type, decoder: Decoder) -> Bool {
        if (try? Metadata(from: decoder)) != nil {
            return true
        }
        
        if (try? ModelType(from: decoder)) != nil {
            return true
        }
        
        return false
    }
    
    public static func makeModelProvider<ModelType: Model>(modelType: ModelType.Type,
                                                           decoder: Decoder) throws -> AnyModelProvider<ModelType> {
        if let appSyncModelProvider = try makeAppSyncModelProvider(modelType: modelType, decoder: decoder) {
            return appSyncModelProvider.eraseToAnyModelProvider()
        }

        return DefaultModelProvider<ModelType>().eraseToAnyModelProvider()
    }
    
    static func makeAppSyncModelProvider<ModelType: Model>(modelType: ModelType.Type,
                                                           decoder: Decoder) throws -> AppSyncModelProvider<ModelType>? {
        if let model = try? ModelType.init(from: decoder) {
            log.verbose("Creating loaded model \(model)")
            return AppSyncModelProvider(model: model)
        } else if let metadata = try? Metadata.init(from: decoder) {
            log.verbose("Creating not loaded model \(modelType.modelName) with metadata \(metadata)")
            return AppSyncModelProvider<ModelType>(metadata: metadata)
        }
        let json = try JSONValue(from: decoder)
        let message = "AppSyncModelProvider could not be created from \(String(describing: json))"
        log.error(message)
        assertionFailure(message)
        return nil
    }
}

extension AppSyncModelDecoder: DefaultLogger { }
