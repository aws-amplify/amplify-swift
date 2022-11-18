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
    
    // TODO: have some sort of priority on the ModelProviderDecoder
    // to indicate run 1 then run 2
    
    public static func shouldDecode<ModelType: Model>(modelType: ModelType.Type, decoder: Decoder) -> Bool {
        if (try? DataStoreModelIdentifierMetadata(from: decoder)) != nil {
            return true
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
        } else if let metadata = try? DataStoreModelIdentifierMetadata.init(from: decoder) {
            return DataStoreModelProvider<ModelType>(metadata: metadata)
        }

        let json = try? JSONValue(from: decoder)
        let message = "DataStoreModelProvider could not be created from \(String(describing: json))"
        Amplify.DataStore.log.error(message)
        assertionFailure(message)
        return nil
    }
}

/// Metadata that contains the primary keys and values of a model
public struct DataStoreModelIdentifierMetadata: Codable {
    let identifier: String?
}
