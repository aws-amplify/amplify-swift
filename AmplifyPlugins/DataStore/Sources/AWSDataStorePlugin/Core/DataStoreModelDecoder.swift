//
//  File.swift
//  
//
//  Created by Law, Michael on 8/24/22.
//

import Foundation
import Amplify

public struct DataStoreModelDecoder: ModelProviderDecoder {
    public static func shouldDecode<ModelType: Model>(modelType: ModelType.Type, decoder: Decoder) -> Bool {
        guard let json = try? JSONValue(from: decoder) else {
            return false
        }
        // TODO: This needs to be more strict once we have more than one decoder running
        // without any sort of priority
        // check if it has the single field

        return true
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
        let json = try? JSONValue(from: decoder)
        
        // Attempt to decode to the entire model as a loaded model provider
        if let model = try? ModelType.init(from: decoder) {
            return DataStoreModelProvider(model: model)
        } else if case .string(let identifier) = json { // A not loaded model provider
            return DataStoreModelProvider<ModelType>(identifier: identifier)
        }
        
        return nil
    }
}
