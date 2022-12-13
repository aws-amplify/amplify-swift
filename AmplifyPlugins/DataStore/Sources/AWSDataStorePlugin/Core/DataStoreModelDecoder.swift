//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify
import SQLite

public struct DataStoreModelDecoder: ModelProviderDecoder {
    
    public static let DataStoreSource = "DataStore"
    
    /// Metadata that contains the foreign key value of a parent model, which is the primary key of the model to be loaded.
    struct Metadata: Codable {
        let identifier: String?
        let source: String
    }
    
    /// Create a SQLite payload that is capable of initializting a LazyReference, by decoding to `DataStoreModelDecoder.Metadata`.
    static func lazyInit(identifier: Binding?) -> [String: Binding?] {
        return ["identifier": identifier, "source": DataStoreSource]
    }
    
    public static func shouldDecode<ModelType: Model>(modelType: ModelType.Type, decoder: Decoder) -> Bool {
        if let metadata = try? DataStoreModelDecoder.Metadata(from: decoder) {
            if metadata.source == DataStoreSource {
                return true
            } else {
                return false
            }
        }
        
        if (try? ModelType(from: decoder)) != nil {
            return true
        }
        
        return false
    }
    
    public static func makeModelProvider<ModelType: Model>(modelType: ModelType.Type,
                                                           decoder: Decoder) throws -> AnyModelProvider<ModelType> {
        
        if let provider = try getDataStoreModelProvider(modelType: modelType, decoder: decoder) {
            return provider.eraseToAnyModelProvider()
        }
        
        return DefaultModelProvider<ModelType>(element: nil).eraseToAnyModelProvider()
    }
    
    static func getDataStoreModelProvider<ModelType: Model>(modelType: ModelType.Type,
                                                            decoder: Decoder) throws -> DataStoreModelProvider<ModelType>? {
        if let model = try? ModelType.init(from: decoder) {
            return DataStoreModelProvider(model: model)
        } else if let metadata = try? Metadata.init(from: decoder) {
            return DataStoreModelProvider<ModelType>(metadata: metadata)
        }

        let json = try? JSONValue(from: decoder)
        let message = "DataStoreModelProvider could not be created from \(String(describing: json))"
        Amplify.DataStore.log.error(message)
        assertionFailure(message)
        return nil
    }
}
