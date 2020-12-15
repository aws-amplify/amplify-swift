//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

public class AppSyncList<ModelType: Model>: List<ModelType>, ModelListDecoder {

    // MARK: Codable

    required convenience public init(from decoder: Decoder) throws {
        let json = try JSONValue(from: decoder)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = ModelDateFormatting.encodingStrategy

        if case let .object(jsonObject) = json,
              case let .array(jsonArray) = jsonObject["items"] {

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = ModelDateFormatting.decodingStrategy
            let elements = try jsonArray.map { (jsonElement) -> ModelType in
                let serializedJSON = try encoder.encode(jsonElement)
                return try decoder.decode(ModelType.self, from: serializedJSON)
            }

            self.init(elements)
            return
        }

        self.init([ModelType]())
    }

    // MARK: ModelListDecoder

    public static func shouldDecode(decoder: Decoder) -> Bool {
        let json = try? JSONValue(from: decoder)

        if case let .object(jsonObject) = json,
           case .array = jsonObject["items"] {
            return true
        }

        return false
    }

    public static func decode<ModelType: Model>(decoder: Decoder,
                                                modelType: ModelType.Type) -> List<ModelType> {
        do {
            return try AppSyncList<ModelType>.init(from: decoder)
        } catch {
            return List([ModelType]())
        }
    }
}
