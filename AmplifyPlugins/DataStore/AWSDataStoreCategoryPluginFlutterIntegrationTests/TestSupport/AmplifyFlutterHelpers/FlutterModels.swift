//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import Foundation

// Contains the set of classes that conforms to the `Model` protocol.
final public class FlutterModels: AmplifyModelRegistration {
    public let version: String = "e9c358927805a236769ad01b2804e6f1"
    
    var modelSchemas: [String: ModelSchema] = [:]
    
    public func addModelSchema(modelName: String, modelSchema: ModelSchema) {
        modelSchemas[modelName] = modelSchema
    }
    
    public func registerModels(registry: ModelRegistry.Type) {
        modelSchemas.forEach { entry in
            ModelRegistry.register(modelType: FlutterSerializedModel.self,
                                   modelSchema: entry.value) { (jsonString, decoder) -> Model in
                let resolvedDecoder: JSONDecoder
                if let decoder = decoder {
                    resolvedDecoder = decoder
                } else {
                    resolvedDecoder = JSONDecoder(dateDecodingStrategy: ModelDateFormatting.decodingStrategy)
                }
                
                // Convert jsonstring to object
                let data = jsonString.data(using: .utf8)!
                let jsonValue = try resolvedDecoder.decode(JSONValue.self, from: data)
                if case .array(let jsonArray) = jsonValue,
                   case .object(let jsonObj) = jsonArray[0],
                   case .string(let id) = jsonObj["id"] {
                    let model = FlutterSerializedModel(id: id, map: jsonObj)
                    return model
                }
                throw DataStoreError.decodingError(
                    "Error in decoding \(jsonString)", "Please create an issue to amplify-flutter repo.")
            }
        }
    }
}
