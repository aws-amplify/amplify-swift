//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AmplifyTestCommon

struct TestFlutterModelRegistration: AmplifyModelRegistration {

    private let flutterModelRegistration: FlutterModels = FlutterModels()
    
    private let decoder: (String, JSONDecoder?) throws -> Model = { (jsonString, decoder) -> Model in
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

    func registerModels(registry: ModelRegistry.Type) {
        
        // TODO: IMPLEMENT THIS CODE ONCE  NESTED TYPES ARE SUPPORTED
//        do {
//           try register()
//        } catch {
//           print(error)
//        }
//
//        flutterModelRegistration.registerModels(registry: ModelRegistry.self)

//        registry.register(modelType: FlutterPost.self, modelSchema: FlutterPost.schema, jsonDecoder: decoder)
        registry.register(modelType: Post.self, modelSchema: Post.schema, jsonDecoder: decoder)
        registry.register(modelType: Comment.self, modelSchema: Comment.schema, jsonDecoder: decoder)
        registry.register(modelType: Project1.self, modelSchema: Project1.schema, jsonDecoder: decoder)
        registry.register(modelType: Team1.self, modelSchema: Team1.schema, jsonDecoder: decoder)
        registry.register(modelType: Project2.self, modelSchema: Project2.schema, jsonDecoder: decoder)
        registry.register(modelType: Team2.self, modelSchema: Team2.schema, jsonDecoder: decoder)
        registry.register(modelType: Post3.self, modelSchema: Post3.schema, jsonDecoder: decoder)
        registry.register(modelType: Comment3.self, modelSchema: Comment3.schema, jsonDecoder: decoder)
        registry.register(modelType: Post4.self, modelSchema: Post4.schema, jsonDecoder: decoder)
        registry.register(modelType: Comment4.self, modelSchema: Comment4.schema, jsonDecoder: decoder)
        registry.register(modelType: Post5.self, modelSchema: Post5.schema, jsonDecoder: decoder)
        registry.register(modelType: PostEditor5.self, modelSchema: PostEditor5.schema, jsonDecoder: decoder)
        registry.register(modelType: User5.self, modelSchema: User5.schema, jsonDecoder: decoder)
        registry.register(modelType: Blog6.self, modelSchema: Blog6.schema, jsonDecoder: decoder)
        registry.register(modelType: Post6.self, modelSchema: Post6.schema, jsonDecoder: decoder)
        registry.register(modelType: Comment6.self, modelSchema: Comment6.schema, jsonDecoder: decoder)
        registry.register(modelType: ScalarContainer.self, modelSchema: ScalarContainer.schema, jsonDecoder: decoder)
        registry.register(modelType: ListIntContainer.self, modelSchema: ListIntContainer.schema, jsonDecoder: decoder)
        registry.register(modelType: ListStringContainer.self, modelSchema: ListStringContainer.schema, jsonDecoder: decoder)
        registry.register(modelType: EnumTestModel.self, modelSchema: EnumTestModel.schema, jsonDecoder: decoder)
        registry.register(modelType: NestedTypeTestModel.self, modelSchema: NestedTypeTestModel.schema, jsonDecoder: decoder)
        registry.register(modelType: CustomerOrder.self, modelSchema: CustomerOrder.schema, jsonDecoder: decoder)
    }
    
    let version: String = "1"
    
    // TODO: IMPLEMENT THIS CODE ONCE  NESTED TYPES ARE SUPPORTED
//    func register() throws {
//        let data = flutterSerializedSchemas.data(using: .utf8)!
//        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]]
//        var modelSchemas: [ModelSchema] = []
//
//        guard let modelSchemaList = json as? [[String: Any]] else {
//            print("failed to cast Flutter schema json")
//            return
//        }
//
//        modelSchemas = try modelSchemaList.map {
//            try FlutterModelSchema.init(serializedData: $0).convertToNativeModelSchema()
//        }
//
//        modelSchemas.forEach { (modelSchema) in
//            flutterModelRegistration.addModelSchema(modelName: modelSchema.name, modelSchema: modelSchema)
//        }
//
//    }

}
