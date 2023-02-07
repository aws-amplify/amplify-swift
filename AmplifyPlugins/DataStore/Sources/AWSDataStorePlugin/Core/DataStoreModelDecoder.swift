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
        let identifiers: [LazyReferenceIdentifier]
        let source: String
        
        init(identifiers: [LazyReferenceIdentifier], source: String = DataStoreSource) {
            self.identifiers = identifiers
            self.source = source
        }
        
        func toJsonObject() -> Any? {
            return [
                "identifiers": identifiers.map({
                    [
                        "name": $0.name,
                        "value": $0.value
                    ]
                }),
                "source": source
            ]
        }
    }
    
    /// Create a SQLite payload that is capable of initializting a LazyReference, by decoding to `DataStoreModelDecoder.Metadata`.
    static func lazyInit(identifiers: [LazyReferenceIdentifier]) -> Metadata? {
        if identifiers.isEmpty {
            return nil
        }
        return Metadata(identifiers: identifiers)
    }
    
    public static func decode<ModelType: Model>(modelType: ModelType.Type, decoder: Decoder) -> AnyModelProvider<ModelType>? {
        if let metadata = try? DataStoreModelDecoder.Metadata(from: decoder) {
            if metadata.source == DataStoreSource {
                return DataStoreModelProvider<ModelType>(metadata: metadata).eraseToAnyModelProvider()
            } else {
                return nil
            }
        }
        
        if let model = try? ModelType.init(from: decoder) {
            return DataStoreModelProvider(model: model).eraseToAnyModelProvider()
        }
        
        return nil
    }
}
