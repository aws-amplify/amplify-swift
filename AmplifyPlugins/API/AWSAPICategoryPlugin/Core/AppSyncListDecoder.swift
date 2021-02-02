//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public struct AppSyncListDecoder: ModelListDecoder {
    public static func shouldDecode<ModelType: Model>(modelType: ModelType.Type, decoder: Decoder) -> Bool {
        guard let json = try? JSONValue(from: decoder) else {
            return false
        }
        return shouldDecode(json: json)
    }

    static func shouldDecode(json: JSONValue) -> Bool {
        if case let .object(jsonObject) = json,
           case .array = jsonObject["items"] {
            return true
        }

        return false
    }

    public static func getListProvider<ModelType: Model>(modelType: ModelType.Type,
                                                         decoder: Decoder) throws -> AnyModelListProvider<ModelType> {
        let json = try JSONValue(from: decoder)

        if case let .object(jsonObject) = json,
              case let .array(jsonArray) = jsonObject["items"] {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
            let elements = try jsonArray.map { (jsonElement) -> ModelType in
                let serializedJSON = try encoder.encode(jsonElement)
                return try decoder.decode(ModelType.self, from: serializedJSON)
            }

            return AppSyncListProvider(elements).eraseToAnyModelListProvider()
        }

        let message = "AppSyncListProvider could not be created from \(String(describing: json))"
        Amplify.DataStore.log.error(message)
        assert(false, message)
        return ArrayLiteralListProvider<ModelType>(elements: []).eraseToAnyModelListProvider()
    }
}
